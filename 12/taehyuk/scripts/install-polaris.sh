helm repo add fairwinds-stable https://charts.fairwinds.com/stable

kubectl create ns polaris

helm install polaris fairwinds-stable/polaris -n polaris
