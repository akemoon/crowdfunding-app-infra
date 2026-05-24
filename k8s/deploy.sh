#!/usr/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

step() { echo -e "\n==> $1"; }

# PostgreSQL
step "PostgreSQL"
kubectl apply -f "$SCRIPT_DIR/postgres/secrets.yaml"
helm upgrade --install pg bitnami/postgresql -f "$SCRIPT_DIR/postgres/values.yaml"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgresql --timeout=120s

# Redis
step "Redis"
kubectl apply -f "$SCRIPT_DIR/redis/secrets.yaml"
helm upgrade --install redis bitnami/redis -f "$SCRIPT_DIR/redis/values.yaml"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=redis --timeout=120s

# Kafka (Strimzi operator must already be installed in kafka namespace)
step "Kafka"
kubectl apply -n kafka -f "$SCRIPT_DIR/kafka/kafka-dual-role.yaml"
kubectl wait kafka/my-cluster --for=condition=Ready --timeout=300s -n kafka
kubectl apply -n kafka -f "$SCRIPT_DIR/kafka/topics.yaml"

# MinIO
step "MinIO"
kubectl apply -f "$SCRIPT_DIR/minio/secrets.yaml"
kubectl apply -f "$SCRIPT_DIR/minio/deploy.yaml"
kubectl apply -f "$SCRIPT_DIR/minio/svc.yaml"
kubectl apply -f "$SCRIPT_DIR/minio/ingress.yaml"
kubectl wait --for=condition=ready pod -l app=minio --timeout=60s
kubectl apply -f "$SCRIPT_DIR/minio/init-job.yaml"

# Monitoring
step "Monitoring"
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
helm upgrade --install kube-prom-stack prometheus-community/kube-prometheus-stack -n monitoring
kubectl apply -f "$SCRIPT_DIR/monitoring/ingress.yaml"
kubectl apply -f "$SCRIPT_DIR/monitoring/svc-monitor.yaml"

# Traefik
step "Traefik"
helm upgrade --install traefik traefik/traefik -f "$SCRIPT_DIR/traefik/values.yaml"
kubectl apply -f "$SCRIPT_DIR/traefik/ingress.yaml"

# Services
step "Services"
kubectl apply -f "$SCRIPT_DIR/noop/"

kubectl apply -f "$SCRIPT_DIR/user/secrets.yaml"
kubectl apply -f "$SCRIPT_DIR/user/deploy.yaml"
kubectl apply -f "$SCRIPT_DIR/user/svc.yaml"
kubectl apply -f "$SCRIPT_DIR/user/hpa.yaml"

kubectl apply -f "$SCRIPT_DIR/project/deploy.yaml"
kubectl apply -f "$SCRIPT_DIR/project/svc.yaml"
kubectl apply -f "$SCRIPT_DIR/project/hpa.yaml"

kubectl apply -f "$SCRIPT_DIR/payment/deploy.yaml"
kubectl apply -f "$SCRIPT_DIR/payment/svc.yaml"
kubectl apply -f "$SCRIPT_DIR/payment/hpa.yaml"

kubectl apply -f "$SCRIPT_DIR/promo/deploy.yaml"
kubectl apply -f "$SCRIPT_DIR/promo/svc.yaml"
kubectl apply -f "$SCRIPT_DIR/promo/hpa.yaml"

kubectl apply -f "$SCRIPT_DIR/front/"

step "Done"
echo "All components deployed."
