#!/bin/bash

set -e
SECONDS=0

echo ""
echo "Helm Registry Login ..."
tar zxfO ~/far/f5-far-auth-key.tgz cne_pull_64.json | helm registry login -u _json_key_base64 --password-stdin https://repo.f5.com

# not required, but leaving here commented out, just in case ...
# echo ""
# echo "Docker Registry Login ..."
# tar zxfO ~/far/f5-far-auth-key.tgz cne_pull_64.json | docker login -u _json_key_base64 --password-stdin https://repo.f5.com

echo ""
echo "Create f5-utils namespace for SPK supporting software, such as DSSM and CRD conversion ..."
kubectl create ns f5-utils || true
kubectl create ns f5-operators || true

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

kubectl -n default  apply -f ~/far/far-secret.yaml
kubectl -n f5-utils apply -f ~/far/far-secret.yaml
kubectl -n f5-operators apply -f ~/far/far-secret.yaml

echo ""
echo "Install OTEL prerequired cert ..."
kubectl apply -f resources/otel-cert.yaml

echo ""
echo "Install Cluster Wide Controller (CWC) to manage license and debug API ..."
rm -rf ~/cwc || true
helm pull oci://repo.f5.com/utils/f5-cert-gen --version 0.9.1  --untar --untardir ~/cwc
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

echo ""
echo "install CSI driver for NFS ..."
helm repo add csi-driver-nfs https://raw.githubusercontent.com/kubernetes-csi/csi-driver-nfs/master/charts
helm upgrade --install csi-driver-nfs csi-driver-nfs/csi-driver-nfs --namespace kube-system --set kubeletDir=/var/lib/kubelet

echo "waiting for pods be ready in kube-system namespace ..."
sleep 2
until kubectl wait --for=condition=Ready pods --all -n kube-system; do
  echo "retrying in 5 secs ..."
  sleep 5
done

kubectl get pods --selector app.kubernetes.io/name=csi-driver-nfs --namespace kube-system
kubectl apply -f resources/storageclass.yaml
kubectl patch storageclass nfs -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
sleep 2
kubectl get storageclass

echo ""
echo "Install F5 Lifecycle Opertaor (FLO) ..."

export JWT=$(cat ~/.jwt)
envsubst < resources/flo-value.yaml >/tmp/flo-value.yaml
helm upgrade --install flo oci://repo.f5.com/charts/f5-lifecycle-operator --version v1.7.8-0.3.37 -f /tmp/flo-value.yaml

# echo ""
# echo "Download Manifest File ..."
# helm pull oci://repo.f5.com/release/f5-bnk-manifest --version 2.0.0-1.7.8-0.3.37
# ls -l f5-bnk-manifest*tgz
# tar zxvf f5-bnk-manifest*tgz
# cat f5-bnk-manifest*/bnk-manifest*yaml | grep f5-spk-crds-common -A 5

echo ""
echo "Install F5 common, service proxy, Gateway API ..."
helm upgrade --install f5-spk-crds-common oci://repo.f5.com/charts/f5-spk-crds-common --version 8.7.4 -f resources/crd-values.yaml
helm upgrade --install f5-spk-crds-service-proxy oci://repo.f5.com/charts/f5-spk-crds-service-proxy --version 8.7.4 -f resources/crd-values.yaml
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/experimental-install.yaml

echo ""
echo "List installed CRDs ..."
kubectl get crd

echo ""
echo "Deployment completed in $SECONDS secs."
