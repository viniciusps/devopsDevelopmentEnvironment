#!/bin/bash

#Install kubectl
echo "Downloading Kubectl for version v${KUBERNETES_VERSION}"
bash -c "wget https://storage.googleapis.com/kubernetes-release/release/v$KUBERNETES_VERSION/bin/linux/amd64/kubectl" 2>/dev/null

chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl

# Install crictl
curl -qL https://github.com/kubernetes-sigs/cri-tools/releases/download/v1.16.1/crictl-v1.16.1-linux-amd64.tar.gz 2>/dev/null | tar xzvf -
chmod +x crictl
sudo mv crictl /usr/local/bin/

#Install stern
# TODO: Check sha256sum
echo "Downloading Stern"
curl -q -Lo stern https://github.com/wercker/stern/releases/download/1.10.0/stern_linux_amd64 2>/dev/null
chmod +x stern
sudo mv stern /usr/local/bin/

#Install kubecfg
# TODO: Check sha256sum
echo "Downloading Kubecfg"
curl -q -Lo kubecfg https://github.com/ksonnet/kubecfg/releases/download/v0.9.0/kubecfg-linux-amd64 2>/dev/null
chmod +x kubecfg
sudo mv kubecfg /usr/local/bin/

## Installing helm

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

