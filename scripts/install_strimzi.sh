#!/bin/bash

kubectl create ns kafka-system

kubectl create ns kafka-dev

kubectl  -n kafka-system create -f https://github.com/strimzi/strimzi-kafka-operator/releases/download/0.27.1/strimzi-crds-0.27.1.yaml

cat << EOF > kafka-operator.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: kafka-operator
  namespace: argocd
spec:
  destination:
    namespace: kafka-system
    server: https://kubernetes.default.svc
  project: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
  source:
    repoURL: https://strimzi.io/charts/
    chart: strimzi-kafka-operator
    targetRevision: 0.27.1
    helm:
      values: |-
        tmpDirSizeLimit: 20Mi
        watchNamespaces:
          - kafka-dev
EOF

kubectl apply -f kafka-operator.yaml

sleep 30

cat << EOF > kafka-cluster.yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: Kafka
metadata:
  name: kafka-dev-cluster
  namespace: kafka-dev
spec:
  kafka:
    replicas: 3
    listeners:
      - name: plain
        port: 9092
        type: internal
        tls: false
      - name: tls
        port: 9093
        type: internal
        tls: true
      - name: external
        port: 9094
        type: nodeport
        tls: false
    storage:
      type: jbod
      volumes:
      - id: 0
        type: persistent-claim
        size: 1Gi
        deleteClaim: false
    config:
      offsets.topic.replication.factor: 1
      transaction.state.log.replication.factor: 1
      transaction.state.log.min.isr: 1
      default.replication.factor: 1
      min.insync.replicas: 1
    template:
      pod:
        securityContext:
          runAsUser: 0
          fsGroup: 0
  zookeeper:
    replicas: 3
    template:
      pod:
        securityContext:
          runAsUser: 0
          fsGroup: 0
    storage:
      type: persistent-claim
      size: 1Gi
      deleteClaim: false
  entityOperator:
    topicOperator: {}
    userOperator: {}
EOF

kubectl apply -f kafka-cluster.yaml

sleep 30

INGRESS_IP=$(cat /home/vagrant/ingress_ip.txt)

cat << 'EOF' > kafka-dashboard.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: kafka-dashboard
  namespace: argocd
spec:
  destination:
    namespace: kafka-dev
    server: https://kubernetes.default.svc
  project: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
  source:
    repoURL: https://akhq.io/
    chart: akhq
    targetRevision: 0.2.6
    helm:
      values: |-
        ingress:
          enabled: true
          #ingressClassName: ""
          annotations:
            kubernetes.io/ingress.class: nginx
          paths:
            - /
          hosts:
            - kafka-dashboard.INGRESS_IP.nip.io
        
        extraEnv:
        - name: JAVA_OPTS
          value: -Dlog4j2.formatMsgNoLookups=true
        - name: TRUSTSTORE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: kafka-dev-cluster-cluster-ca-cert 
              key: ca.password

        extraVolumeMounts:
          - name: truststore
            mountPath: /tls/truststore
            readOnly: true

        extraVolumes:
          - name: truststore
            secret:
              secretName: kafka-dev-cluster-cluster-ca-cert 

        secrets:
          akhq:
            connections:
              default:
                properties:
                  bootstrap.servers: 'kafka-dev-cluster-kafka-bootstrap:9093'
                  security.protocol: SSL
                  ssl.truststore.type: PKCS12
                  ssl.truststore.location: /tls/truststore/ca.p12
                  ssl.truststore.password: ${TRUSTSTORE_PASSWORD}
EOF

sed -i -e s/INGRESS_IP/$INGRESS_IP/ kafka-dashboard.yaml 

kubectl apply -f kafka-dashboard.yaml 

cat << EOF > kafka-topic.yaml
apiVersion: kafka.strimzi.io/v1beta2
kind: KafkaTopic
metadata:
  name: hip-topic
  namespace: kafka-dev
  labels:
    strimzi.io/cluster: "kafka-dev-cluster"
spec:
  partitions: 3
  replicas: 1
EOF

kubectl apply -f kafka-topic.yaml

sudo apt-get update && sudo apt-get install kafkacat -y 

sleep 30

#openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -addext "subjectAltName = DNS:registry.172.28.128.32.nip.io" -subj '/O=My Company Name LTD./C=US'

#kubectl -n argocd create secret tls registry-tls --key="tls.key" --cert="tls.crt"

kubectl -n kafka-dev create secret generic docker-creds --from-file=.dockerconfigjson=/home/vagrant/.docker/config.json --type=kubernetes.io/dockerconfigjson


# BROKER_PORT=$(kubectl get svc -n kafka-dev | grep kafka-dev-cluster-kafka-0 | awk '{print $5}' | cut -d: -f2|cut -d/ -f1)

# echo "Message from kafkacat" | kafkacat -b localhost:$BROKER_PORT -t hip-topic

# kafkacat -b localhost:$BROKER_PORT -t hip-topic -C