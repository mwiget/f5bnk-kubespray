# f5bnk-kubespray

Deploy F5 BNK https://clouddocs.f5.com/bigip-next-for-kubernetes/2.0.0-GA/ on baremetal node
with Nvidia Bluefield-3 using kubespray.

## Requirements

- f5-far-auth-key.tgz (download from myf5.com, place the tgz file in ~/far/ folder)
- JWT Token placed in file ~/.jwt
- docker or podman
- kubectl, helm, yq
- baremetal server with Nvidia Bluefield-3
- NFS server, referenced in resources/storageclass.yaml. Adjust accordingly

Example /etc/exports flags

```
/share/bnk  *(rw,sync,no_subtree_check,no_root_squash)
```

## Deployment

- Create and adjust .env

```
  cp .env.example .env
```


- Deploy via Makefile

```
make
```

## Destroy cluster

```
make clean-all
```

## Resources

- F5 BIG-IP Next for Kubernetes on NVIDIA BlueField-3 https://clouddocs.f5.com/bigip-next-for-kubernetes/2.0.0-GA/
- https://github.com/kubernetes-sigs/kubespray (source of sample inventory)
- https://github.com/f5devcentral/f5-bnk-nvidia-bf3-installations
