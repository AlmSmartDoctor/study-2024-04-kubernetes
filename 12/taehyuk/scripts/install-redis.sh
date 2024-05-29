helm repo add bitnami https://charts.bitnami.com/bitnami

kubectl create ns redis

helm install redis bitnami/redis -n redis

