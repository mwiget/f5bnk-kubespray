#!/usr/bin/env bash

set -e
SECONDS=0

echo ""
echo "Helm Registry Login using cne_pull_64.json from ~/far/f5-far-auth-key.tgz ..."
tar zxfO ~/far/f5-far-auth-key.tgz cne_pull_64.json | helm registry login -u _json_key_base64 --password-stdin https://repo.f5.com

# Pulling f5-bigip-k8s-manifest is only required to manually pull containers to use
# in an air gapped local artifactory
#
# BNKVERSION="2.1.0-3.1736.1-0.1.27"
# echo "Pull release/f5-bigip-k8s-manifest version $BNKVERSION ..."
# helm pull oci://repo.f5.com/release/f5-bigip-k8s-manifest --version $BNKVERSION
# echo "Extracting ..."
# tar zxvf f5-bigip-k8s-manifest-$BNKVERSION.tgz

echo ""
echo "F5 Artifacts Registry (FAR) authentication token ..."

# Read the content of cne_pull_64.json into the SERVICE_ACCOUNT_KEY variable
SERVICE_ACCOUNT_KEY=$(tar zxOf ~/far/f5-far-auth-key.tgz)
# Create the SERVICE_ACCOUNT_K8S_SECRET variable by appending "_json_key_base64:" to the base64 encoded SERVICE_ACCOUNT_KEY
SERVICE_ACCOUNT_K8S_SECRET=$(echo "_json_key_base64:${SERVICE_ACCOUNT_KEY}" | base64 -w 0)

echo ""
echo "Create the secret.yaml file with the provided content ..."
cat << EOF > ~/far/far-secret.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: far-secret
data:
  .dockerconfigjson: $(echo "{\"auths\": {\
\"repo.f5.com\":\
{\"auth\": \"$SERVICE_ACCOUNT_K8S_SECRET\"}}}" | base64 -w 0)
type: kubernetes.io/dockerconfigjson
EOF

echo ""
echo "Create far-secret in f5-utils and f5-operators namespaces ..."
kubectl create ns f5-utils || true
kubectl create ns f5-operators || true

kubectl -n default  apply -f ~/far/far-secret.yaml
kubectl -n f5-utils apply -f ~/far/far-secret.yaml
kubectl -n f5-operators apply -f ~/far/far-secret.yaml

echo ""
echo "Install OTEL prerequired cert ..."
kubectl apply -f resources/otel-cert.yaml

echo ""
echo "Install Cluster Wide Controller (CWC) to manage license and debug API ..."
rm -rf ~/cwc || true
helm pull oci://repo.f5.com/utils/f5-cert-gen --version 0.9.3  --untar --untardir ~/cwc
mv ~/cwc/f5-cert-gen ~/cwc/cert-gen
pushd ~/cwc && sh cert-gen/gen_cert.sh -s=api-server -a=f5-spk-cwc.f5-utils -n=1 && popd
kubectl apply -f ~/cwc/cwc-license-certs.yaml -n f5-utils

echo "Create directory for API client certs for easier reference ..."
pushd ~/cwc && \
  mkdir -p cwc_api && \
  cp api-server-secrets/ssl/client/certs/client_certificate.pem \
  api-server-secrets/ssl/ca/certs/ca_certificate.pem \
  api-server-secrets/ssl/client/secrets/client_key.pem \
  cwc_api
popd

echo "waiting for pods be ready in kube-system namespace ..."
sleep 2
until kubectl wait --for=condition=Ready pods --all -n kube-system; do
  echo "retrying in 5 secs ..."
  sleep 5
done

echo ""
echo "Install F5 Lifecycle Opertaor (FLO) ..."

export JWT=$(cat ~/.jwt)
if cut -d\. -f1 ~/.jwt | base64 -d | grep tst; then
  envsubst < resources/flo-value-tst.yaml >/tmp/flo-value.yaml
else
  envsubst < resources/flo-value.yaml >/tmp/flo-value.yaml
fi

helm upgrade --install flo oci://repo.f5.com/charts/f5-lifecycle-operator --version v1.198.4-0.1.36 -f /tmp/flo-value.yaml --namespace f5-operators

echo ""
echo "Deployment completed in $SECONDS secs."
