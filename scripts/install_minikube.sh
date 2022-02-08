#!/bin/bash

sudo apt install conntrack -y

#Install minikube
echo "Downloading Minikube"
curl -q -Lo minikube https://storage.googleapis.com/minikube/releases/v1.24.0/minikube-linux-amd64 2>/dev/null
chmod +x minikube
sudo mv minikube /usr/local/bin/

#Setup minikube
echo "127.0.0.1 minikube minikube." | sudo tee -a /etc/hosts
mkdir -p $HOME/.minikube
mkdir -p $HOME/.kube
touch $HOME/.kube/config

export KUBECONFIG=$HOME/.kube/config

# Permissions
sudo chown -R $USER:$USER $HOME/.kube
sudo chown -R $USER:$USER $HOME/.minikube

export MINIKUBE_WANTUPDATENOTIFICATION=false
export MINIKUBE_WANTREPORTERRORPROMPT=false
export MINIKUBE_HOME=$HOME
export CHANGE_MINIKUBE_NONE_USER=true
export KUBECONFIG=$HOME/.kube/config

ip=$(ifconfig  eth1 | grep "inet "  | awk '{print $2}')

cat << EOF > /home/vagrant/start_minikube.sh
#!/bin/bash

sudo -E minikube start -v 4 --memory=6g --cpus=4 --vm-driver none --kubernetes-version v${KUBERNETES_VERSION} --bootstrapper kubeadm --insecure-registry="registry.${ip}.nip.io"  2>/dev/null

# Permissions
sudo chown -R $USER:$USER $HOME/.kube
sudo chown -R $USER:$USER $HOME/.minikube
EOF

echo "sudo -E minikube stop" > /home/vagrant/stop_minikube.sh

chmod +x /home/vagrant/start_minikube.sh
chmod +x /home/vagrant/stop_minikube.sh
