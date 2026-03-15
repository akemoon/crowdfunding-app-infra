#!/usr/bin/bash
set -e

APP_DIR="$(cd "$(dirname "$0")/../../" && pwd)"

declare -A SERVICES=(
  [user]="crowdfunding-app-user"
  [project]="crowdfunding-app-project"
  [payment]="crowdfunding-app-payment"
  [promo]="crowdfunding-app-promo"
)

INFRA_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "==> Building and loading images into Minikube..."

echo "[BUILD] minio-init"
docker build -t minio-init:latest "$INFRA_DIR/minio"
minikube image load minio-init:latest

for svc in "${!SERVICES[@]}"; do
  image="${SERVICES[$svc]}:latest"
  context="$APP_DIR/$svc"

  echo "[BUILD] $svc -> $image"
  docker build -t "$image" "$context"

  echo "[LOAD]  $image -> minikube"
  minikube image load "$image"
done

echo "==> Done"
