#!/bin/bash

## Addons
sudo -E minikube addons  enable ingress

## Configured eth1 as minikube IP since vagrant uses eth0 as NAT

ip=$(ifconfig  eth1 | grep "inet "  | awk '{print $2}')
echo $ip > /home/vagrant/ingress_ip.txt

cat << EOF > /home/vagrant/ingress-nginx-patch.yaml
spec:
  externalIPs:
    - $ip
EOF

kubectl patch svc ingress-nginx-controller -n ingress-nginx --patch "$(cat /home/vagrant/ingress-nginx-patch.yaml)"

