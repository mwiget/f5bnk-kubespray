SHELL := /bin/bash

all: cluster extras bnk

cluster: k8s-cluster kubeconfig single-node-fix-coredns sriov

extras: cert-manager grafana nvidia-gpu-operator

kubespray:
	set -a; source ./.env && $$DOCKER run --rm -ti --mount type=bind,source="$$(pwd)"/inventory/$$CLUSTER/,dst=/inventory \
		--mount type=bind,source="$$SSH_PRIVATE_KEY,dst=/root/.ssh/id_rsa" \
		quay.io/kubespray/kubespray:v2.28.1 bash

k8s-cluster:
	set -a; source ./.env && $$DOCKER run --rm -ti --mount type=bind,source="$$(pwd)"/inventory/$$CLUSTER/,dst=/inventory \
		--mount type=bind,source="$$SSH_PRIVATE_KEY,dst=/root/.ssh/id_rsa" \
		quay.io/kubespray/kubespray:v2.28.1 \
		ansible-playbook -i /inventory/inventory.yaml \
		--private-key /root/.ssh/id_rsa -e ingress_nginx_enabled=false cluster.yml

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
	kubectl apply -f resources/nad-vf.yaml

cert-manager:
	helm repo add jetstack https://charts.jetstack.io --force-update
	helm upgrade --install -n cert-manager cert-manager jetstack/cert-manager --create-namespace --version v1.16.1 --set crds.enabled=true --wait
	kubectl wait --for=condition=Ready pods --all -n cert-manager
	kubectl apply -f resources/cluster-issuer.yaml

grafana:
	kubectl get ns monitoring || kubectl create ns monitoring
	kubectl apply -f resources/prometheus-cert.yaml -n monitoring
	helm repo add prometheus-community \
		 https://prometheus-community.github.io/helm-charts --force-update
	helm install prometheus prometheus-community/kube-prometheus-stack \
			--create-namespace --namespace monitoring \
			--values resources/prometheus-values.yaml || echo "already installed"
	until kubectl wait --for=condition=Ready pods --all -n monitoring --timeout 30s; do \
		echo "trying again in 5 secs ..." ; \
		sleep 5 ; \
	done
	kubectl apply -f resources/grafana-service.yaml -n monitoring

nvidia-gpu-operator:
	helm repo add nvidia https://nvidia.github.io/gpu-operator --force-update
	helm repo update
	helm upgrade --install --namespace gpu-operator --create-namespace \
		gpu-operator nvidia/gpu-operator

bnk:
	./scripts/check-requirements.sh
	./scripts/decode-jwt.sh ~/.jwt
	./scripts/install-bnk.sh
	./scripts/deploy-bnkgwc.sh

clean-bnk:
	kubectl delete -f resources/bnkgatewayclass.yaml || true

clean-dpu:
	set -a; source ./.env && ./scripts/cleanup-dpu-k8s.sh $$(pwd)/inventory/$${CLUSTER}/inventory.yaml

clean-all: clean-dpu
	set -a; source ./.env && \
	 $${DOCKER} run --rm -ti \
	   --mount type=bind,source="$$(pwd)/inventory/$${CLUSTER}",dst=/inventory \
	   --mount type=bind,source="$${SSH_PRIVATE_KEY}",dst=/root/.ssh/id_rsa \
	   quay.io/kubespray/kubespray:v2.28.1 \
	   /bin/bash -lc '\
	     ansible-playbook -i /inventory/inventory.yaml --private-key /root/.ssh/id_rsa playbooks/facts.yml -vv && \
	     ansible-playbook -i /inventory/inventory.yaml --private-key /root/.ssh/id_rsa reset.yml \
	       -e reset_confirmation=yes --limit "all:!*-dpu"'

