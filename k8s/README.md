## Monitoring core 

Install monitoring stack:
```
kubectl create namespace monitoring

helm install kube-prom-stack prometheus-community/kube-prometheus-stack -n monitoring
```

Create ingress:
```
kubectl apply -f k8s/monitoring/ingress.yaml
```

Get the Minikube IP:
```
minikube ip
```

... then add it to `/etc/hosts`:
```
# Minikube
<minikube-ip> grafana.app.local
<minikube-ip> api.app.local
<minikube-ip> prom.app.local
```

Enable the Ingress addon:
```
minikube addons enable ingress
```

Start the Minikube tunnel (keep it running in a separate terminal):
```
minikube tunnel
```

## Postgres

Using the Bitnami [chart](https://github.com/bitnami/charts/tree/b5e10d87d6d6925f7afe12f1119b1aa0465b5f0c/bitnami/postgresql).

To add the Bitnami repo, run:
```
helm repo add bitnami https://charts.bitnami.com/bitnami

helm repo update
```

Add secrets and release:
```bash
kubectl apply -f k8s/postgres/secrets.yaml

helm install pg bitnami/postgresql -f k8s/postgres/values.yaml
```

Also you can add Adminer UI:
```bash
kubectl apply -f k8s/postgres/adminer.yaml
```

## Redis

Using the Bitnami [chart](https://github.com/bitnami/charts/tree/58cfc4ede895bc2a1ca8da297f9a499c40c09714/bitnami/redis).

Add secrets and release:
```
kubectl apply -f k8s/redis/secrets.yaml

helm install redis bitnami/redis -f k8s/redis/values.yaml
```

## Kafka

Using Strimzi cluster operator. Quick start guide [here](https://strimzi.io/quickstarts/).

Create topics:
```bash
kubectl apply -f k8s/kafka/topics.yaml -n kafka
```

### Redpanda UI

```bash
helm install console redpanda/console -f k8s/kafka/console-values.yaml -n kafka
```

## MinIO

```bash
./k8s/build-load.sh

kubectl apply -f k8s/minio/secrets.yaml

helm install minio bitnami/minio -f k8s/minio/values.yaml

kubectl apply -f k8s/minio/init-job.yaml
```

## Traefik

Installation guide [here](https://doc.traefik.io/traefik/getting-started/install-traefik/).
