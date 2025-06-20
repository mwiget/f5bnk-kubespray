#
#
all: cluster kubeconfig untaint-control-plane sriov cert-manager grafana \
	taint-dpu-node nvidia-gpu-operator \
	bnk bnk-gateway-class

print:
	set -a; source ./.env; echo $$DPU_NODES

cluster:
	set -a; source ./.env; $$DOCKER run --rm -ti --mount type=bind,source="$$(pwd)"/inventory/$$CLUSTER/,dst=/inventory,Z,U \
  	--mount type=bind,source="$$SSH_PRIVATE_KEY,dst=/root/.ssh/id_rsa,Z" \
    quay.io/kubespray/kubespray:v2.28.0 \
		ansible-playbook -i /inventory/inventory.ini --private-key /root/.ssh/id_rsa cluster.yml \
		-e schedule_on_control_plane=true \
		-e kube_network_plugin=calico \
		-e kube_network_plugin_multus=true

kubeconfig:
	set -a; source ./.env; ssh $$CLUSTER "sudo cp /etc/kubernetes/admin.conf /tmp && sudo chmod a+r /tmp/admin.conf"
	mkdir -p ~/.kube
	set -a; source ./.env; scp $$CLUSTER:/tmp/admin.conf ~/.kube/config
	set -a; source ./.env; ssh $$CLUSTER "sudo rm -f /tmp/admin.conf"
	set -a; source ./.env; sed -i.bak "s/127\\.0\\.0\\.1/$$CLUSTER/g" ~/.kube/config
	kubectl get node -o wide

untaint-control-plane:
	set -a; source ./.env; kubectl taint node $$CLUSTER node-role.kubernetes.io/control-plane:NoSchedule-

sriov:
	kubectl apply -f resources/multus.yaml
	kubectl apply -f resources/cni-plugins.yaml
	kubectl apply -f resources/sriovdp-config.yaml
	kubectl apply -f resources/sriov-cni-daemonset.yaml
	kubectl apply -f https://raw.github.com/k8snetworkplumbingwg/sriov-network-device-plugin/master/deployments/sriovdp-daemonset.yaml
	kubectl apply -f resources/nad-sf.yaml

cert-manager:
	helm repo add jetstack https://charts.jetstack.io --force-update
	helm upgrade --install -n cert-manager cert-manager jetstack/cert-manager --create-namespace --version v1.16.1 --set crds.enabled=true --wait
	kubectl wait --for=condition=Ready pods --all -n cert-manager
	kubectl apply -f resources/cluster-issuer.yaml

taint-dpu-node:
	set -a; source ./.env; for node in $$DPU_NODES; do kubectl taint node $$node dpu=true:NoSchedule; done

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
	./scripts/install-bnk.sh

bnk-gateway-class:
	./scripts/deploy-bnkgwc.sh

bfb-install:
	set -a; source ./.env; for node in $$DPU_HOST_NODES; do \
		rsync -avuz dpu $$node:; \
		ssh $$node "cd dpu && ./deploy-bf-bundle.sh"; done

clean-all:
	set -a; source ./.env ; $$DOCKER run --rm -ti --mount type=bind,source="$$(pwd)"/inventory/$$CLUSTER/,dst=/inventory,Z,U \
  	--mount type=bind,source="$$SSH_PRIVATE_KEY,dst=/root/.ssh/id_rsa,Z" \
    quay.io/kubespray/kubespray:v2.28.0 \
		ansible-playbook -i /inventory/inventory.ini --private-key /root/.ssh/id_rsa reset.yml \
		-e reset_confirmation=yes
