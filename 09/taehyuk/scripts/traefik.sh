helm repo add traefik https://traefik.github.io/charts

helm repo update

kubectl create ns traefik

helm install traefik traefik/traefik -n traefik

kubectl port-forward $(kubectl get pods -n traefik --selector "app.kubernetes.io/name=traefik" --output=name) 9000:9000 -n traefik

echo "https://doc.traefik.io/traefik/v2.3/reference/dynamic-configuration/kubernetes-crd/#definitions"