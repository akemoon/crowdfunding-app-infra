#!/usr/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

step() { echo -e "\n==> $1"; }

# Namespaces
step "Namespaces"
kubectl apply -f "$SCRIPT_DIR/namespaces.yaml"
kubectl create namespace kafka --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# TLS secret — copy app-local-tls from default into front, back, data
step "TLS Secrets"
for ns in front back data; do
  TLS_CRT=$(kubectl get secret app-local-tls -n default -o jsonpath='{.data.tls\.crt}' 2>/dev/null || true)
  TLS_KEY=$(kubectl get secret app-local-tls -n default -o jsonpath='{.data.tls\.key}' 2>/dev/null || true)
  if [ -n "$TLS_CRT" ] && [ -n "$TLS_KEY" ]; then
    kubectl create secret tls app-local-tls -n "$ns" \
      --cert=<(echo "$TLS_CRT" | base64 -d) \
      --key=<(echo "$TLS_KEY" | base64 -d) \
      --dry-run=client -o yaml | kubectl apply -f -
  else
    echo "WARNING: app-local-tls not found in default namespace, skipping $ns"
  fi
done

# PostgreSQL (data)
step "PostgreSQL"
kubectl apply -f "$SCRIPT_DIR/data/postgres/secrets.yaml"
helm upgrade --install pg bitnami/postgresql -n data -f "$SCRIPT_DIR/data/postgres/values.yaml"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=postgresql -n data --timeout=120s

# Redis (data)
step "Redis"
kubectl apply -f "$SCRIPT_DIR/data/redis/secrets.yaml"
helm upgrade --install redis bitnami/redis -n data -f "$SCRIPT_DIR/data/redis/values.yaml"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=redis -n data --timeout=120s

# Kafka (kafka)
step "Kafka"
kubectl apply -n kafka -f "$SCRIPT_DIR/kafka/kafka-dual-role.yaml"
kubectl wait kafka/my-cluster --for=condition=Ready --timeout=300s -n kafka
kubectl apply -n kafka -f "$SCRIPT_DIR/kafka/topics.yaml"

# MinIO (data)
step "MinIO"
kubectl apply -f "$SCRIPT_DIR/data/minio/secrets.yaml"
kubectl apply -f "$SCRIPT_DIR/data/minio/deploy.yaml"
kubectl apply -f "$SCRIPT_DIR/data/minio/svc.yaml"
kubectl apply -f "$SCRIPT_DIR/data/minio/ingress.yaml"
kubectl wait --for=condition=ready pod -l app=minio -n data --timeout=60s
kubectl apply -f "$SCRIPT_DIR/data/minio/init-job.yaml"

# Data tools (data)
step "Data tools"
kubectl apply -f "$SCRIPT_DIR/data/pgadmin/secrets.yaml"
kubectl apply -f "$SCRIPT_DIR/data/pgadmin/deploy.yaml"
kubectl apply -f "$SCRIPT_DIR/data/pgadmin/svc.yaml"
kubectl apply -f "$SCRIPT_DIR/data/redisinsight/deploy.yaml"
kubectl apply -f "$SCRIPT_DIR/data/redisinsight/svc.yaml"

# Monitoring
step "Monitoring"
helm upgrade --install kube-prom-stack prometheus-community/kube-prometheus-stack -n monitoring
kubectl apply -f "$SCRIPT_DIR/monitoring/ingress.yaml"

# Traefik (ingress)
step "Traefik"
helm upgrade --install traefik traefik/traefik -n ingress -f "$SCRIPT_DIR/ingress/traefik/values.yaml"
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=traefik -n ingress --timeout=120s

# Backend (back)
step "Backend"
kubectl apply -f "$SCRIPT_DIR/back/secrets.yaml"
kubectl apply -f "$SCRIPT_DIR/back/noop/deploy.yaml"
kubectl apply -f "$SCRIPT_DIR/back/noop/svc.yaml"

kubectl apply -f "$SCRIPT_DIR/back/user/secrets.yaml"
kubectl apply -f "$SCRIPT_DIR/back/user/deploy.yaml"
kubectl apply -f "$SCRIPT_DIR/back/user/svc.yaml"
kubectl apply -f "$SCRIPT_DIR/back/user/hpa.yaml"

kubectl apply -f "$SCRIPT_DIR/back/project/deploy.yaml"
kubectl apply -f "$SCRIPT_DIR/back/project/svc.yaml"
kubectl apply -f "$SCRIPT_DIR/back/project/hpa.yaml"

kubectl apply -f "$SCRIPT_DIR/back/payment/deploy.yaml"
kubectl apply -f "$SCRIPT_DIR/back/payment/svc.yaml"
kubectl apply -f "$SCRIPT_DIR/back/payment/hpa.yaml"

kubectl apply -f "$SCRIPT_DIR/back/promo/deploy.yaml"
kubectl apply -f "$SCRIPT_DIR/back/promo/svc.yaml"
kubectl apply -f "$SCRIPT_DIR/back/promo/hpa.yaml"

kubectl apply -f "$SCRIPT_DIR/back/traefik/ingress.yaml"
kubectl apply -f "$SCRIPT_DIR/back/svc-monitor.yaml"

# Frontend (front)
step "Frontend"
kubectl apply -f "$SCRIPT_DIR/front/deploy.yaml"
kubectl apply -f "$SCRIPT_DIR/front/svc.yaml"
kubectl apply -f "$SCRIPT_DIR/front/ingress.yaml"

step "Done"
echo "All components deployed."
