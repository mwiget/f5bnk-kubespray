#
#

all: cluster kubeconfig single-node-fix-coredns sriov cert-manager grafana \
	nvidia-gpu-operator bnk bnk-gateway-class

cluster:
	set -a; source ./.env; $$DOCKER run --rm -ti --mount type=bind,source="$$(pwd)"/inventory/$$CLUSTER/,dst=/inventory,Z,U \
  	--mount type=bind,source="$$SSH_PRIVATE_KEY,dst=/root/.ssh/id_rsa,Z" \
    quay.io/kubespray/kubespray:v2.28.0 \
		ansible-playbook -i /inventory/inventory.yaml \
		--private-key /root/.ssh/id_rsa cluster.yml \
		-e ingress_nginx_enabled=false

kubeconfig:
	./scripts/get-kubeconfig.sh

single-node-fix-coredns:
	./scripts/coredns-single-node.sh

sriov:
	kubectl apply -f resources/multus.yaml
	kubectl apply -f resources/cni-plugins.yaml
	kubectl apply -f resources/sriovdp-config.yaml
	kubectl apply -f resources/sriov-cni-daemonset.yaml
	kubectl apply -f resources/sriovdp-daemonset.yaml
	kubectl apply -f resources/nad-sf.yaml

cert-manager:
	helm repo add jetstack https://charts.jetstack.io --force-update
	helm upgrade --install -n cert-manager cert-manager jetstack/cert-manager --create-namespace --version v1.16.1 --set crds.enabled=true --wait
	kubectl wait --for=condition=Ready pods --all -n cert-manager
	kubectl apply -f resources/cluster-issuer.yaml

grafana:
	kubectl get ns monitoring || kubectl create ns monitoring
	kubectl apply -f resources/prometheus-cert.yaml -n monitoring
	helm repo add prometheus-community \
		 https://prometheus-community.github.io/helm-charts
	helm install prometheus prometheus-community/kube-prometheus-stack \
			--create-namespace --namespace monitoring \
			--values resources/prometheus-values.yaml || echo "already installed"
	until kubectl wait --for=condition=Ready pods --all -n monitoring --timeout 30s; do \
		echo "trying again in 5 secs ..." ; \
		sleep 5 ; \
	done
	kubectl apply -f resources/grafana-service.yaml -n monitoring

nvidia-gpu-operator:
	helm repo add nvidia https://nvidia.github.io/gpu-operator
	helm repo update
	helm install --namespace gpu-operator --create-namespace \
		gpu-operator nvidia/gpu-operator

bnk:
	./scripts/check-requirements.sh
	./scripts/decode-jwt.sh ~/.jwt
	./scripts/install-bnk.sh

bnk-gateway-class:
	./scripts/deploy-bnkgwc.sh

clean-all:
	set -a; source ./.env ; $$DOCKER run --rm -ti --mount type=bind,source="$$(pwd)"/inventory/$$CLUSTER/,dst=/inventory,Z,U \
  	--mount type=bind,source="$$SSH_PRIVATE_KEY,dst=/root/.ssh/id_rsa,Z" \
    quay.io/kubespray/kubespray:v2.28.0 \
		ansible-playbook -i /inventory/inventory.yaml --private-key /root/.ssh/id_rsa reset.yml \
		-e reset_confirmation=yes
