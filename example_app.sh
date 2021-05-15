#!/bin/bash

helm repo add bitnami https://charts.bitnami.com/bitnami
helm install my-release bitnami/nginx

echo "Waiting to create nginx entry point"
sleep 10

cat << EOF > nginx-entrypoint.yaml
apiVersion: networking.k8s.io/v1beta1
kind: Ingress
metadata:
  name: kubecost-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  - host: www.test.com
    http:
      paths:
      - path: /
        backend:
          serviceName: my-release-nginx
          servicePort: 80
EOF

kubectl apply -f nginx-entrypoint.yaml