#!/bin/bash

sleep 30 

export INGRESS_HOST=$(cat /home/vagrant/ingress_ip.txt)

cat << EOF > /home/vagrant/argocd.values.yaml
server:
  ingress:
    enabled: true
  extraArgs:
  - --insecure
installCRDs: false
EOF

helm repo add argo https://argoproj.github.io/argo-helm

helm install \
    argocd argo/argo-cd \
    --namespace argocd \
    --create-namespace \
    --version 3.30.0 \
    --set server.ingress.hosts="{argocd.$INGRESS_HOST.nip.io}" \
    --values /home/vagrant/argocd.values.yaml \
    --wait

sleep 30 

export PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)


# cat << EOF > /home/vagrant/argocd-ingress.yaml
# apiVersion: extensions/v1beta1
# kind: Ingress
# metadata:
#   name: argocd-server-ingress
#   namespace: argocd
#   annotations:
#     kubernetes.io/ingress.class: nginx
#     nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
#     nginx.ingress.kubernetes.io/ssl-passthrough: "true"
# spec:
#   rules:
#   - host: argocd.$INGRESS_HOST.nip.io
#     http:
#       paths:
#       - backend:
#           serviceName: argocd-server
#           servicePort: https
# EOF
# sleep 10

# kubectl apply -f /home/vagrant/argocd-ingress.yaml

curl --insecure https://argocd.$INGRESS_HOST.nip.io/download/argocd-linux-amd64 -o argocd 2>/dev/null

chmod +x argocd
sudo mv argocd /usr/local/bin/


argocd login \
    --insecure \
    --username admin \
    --password $PASS \
    --grpc-web \
    argocd.$INGRESS_HOST.nip.io



echo "ArgoCD admin password: $PASS"

