#!/usr/bin/bash
set -e

APP_DIR="$(cd "$(dirname "$0")/../../" && pwd)"
INFRA_DIR="$(cd "$(dirname "$0")" && pwd)"

# Build directly into Minikube's Docker daemon
eval "$(minikube docker-env)"

build_svc() {
  local svc=$1
  local image="crowdfunding-app-${svc}:latest"
  echo "[BUILD] $svc -> $image"
  docker build -t "$image" "$APP_DIR/$svc"
  echo "[DEPLOY] restarting $svc"
  kubectl delete pods -l app="$svc" -n back 2>/dev/null || true
}

build_front() {
  echo "[BUILD] front -> crowdfunding-app-front:latest"
  docker build \
    --build-arg PUBLIC_API_URL=https://api.app.local \
    -t crowdfunding-app-front:latest \
    "$APP_DIR/front"
  echo "[DEPLOY] restarting front"
  kubectl delete pods -l app=front -n front 2>/dev/null || true
}

build_minio_init() {
  echo "[BUILD] minio-init"
  docker build -t minio-init:latest "$INFRA_DIR/data/minio"
}

ALL=(user project payment promo front minio-init)

TARGETS=("${@:-${ALL[@]}}")

echo "==> Building: ${TARGETS[*]}"

for target in "${TARGETS[@]}"; do
  case "$target" in
    user|project|payment|promo) build_svc "$target" ;;
    front)                       build_front ;;
    minio-init)                  build_minio_init ;;
    *) echo "[WARN] unknown target: $target"; exit 1 ;;
  esac
done

echo "==> Done"
