#!/bin/bash

KUBERNETES_VERSION=1.20.9

echo "Starting up minikube..."
minikube start -v 4 --memory=6g --cpus=4 --vm-driver hyperkit --kubernetes-version v${KUBERNETES_VERSION} --bootstrapper kubeadm

sleep 20

echo "Enabling ingress..."
minikube addons  enable ingress

MINIKUBE_IP=$(minikube ip)

cat << EOF > ./ingress-nginx-patch.yaml
spec:
  externalIPs:
    - $MINIKUBE_IP
EOF

kubectl patch svc ingress-nginx-controller -n ingress-nginx --patch "$(cat ./ingress-nginx-patch.yaml)"
echo "Ingress ip patched!!!"

cat << EOF > ./argocd.values.yaml
server:
  ingress:
    enabled: true
  extraArgs:
  - --insecure
installCRDs: false
EOF

echo "Installing Argocd..."
sleep 30

helm repo add argo https://argoproj.github.io/argo-helm

helm install \
    argocd argo/argo-cd \
    --namespace argocd \
    --create-namespace \
    --version 3.30.0 \
    --set server.ingress.hosts="{argocd.$MINIKUBE_IP.nip.io}" \
    --values ./argocd.values.yaml \
    --wait

sleep 30 

echo "Installing kafka strimi cluster..."
kubectl create ns kafka-system

kubectl create ns kafka-dev

kubectl  -n kafka-system create -f https://github.com/strimzi/strimzi-kafka-operator/releases/download/0.27.1/strimzi-crds-0.27.1.yaml

kubectl apply -f manifests/kafka-operator.yaml

sleep 30

kubectl apply -f manifests/kafka-cluster.yaml

sed -i -e s/INGRESS_IP/$MINIKUBE_IP/ manifests/kafka-dashboard.yaml 

kubectl apply -f manifests/kafka-dashboard.yaml 

kubectl apply -f manifests/kafka-topic.yaml

if [ -f ~/.docker/config.json ]; then
  echo "Creating docker secret from local docker credentials file"
  kubectl -n kafka-dev create secret generic docker-creds --from-file=.dockerconfigjson=~/.docker/config.json --type=kubernetes.io/dockerconfigjson
fi

## Demo commands

#kubectl apply -f kafka-connect.yaml

#kubectl apply -f kafka-connector.yaml

export PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "ArgoCD User: admin, Password: $PASS"