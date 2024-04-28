#!/bin/bash

cat <<EOF > nginx-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
spec:
  containers:
  - name: nginx-pod
    image: nginx:1.19.19 
EOF

kubectl apply -f nginx-pod.yaml

kubectl wait --for=condition=complete pod/nginx-pod --timeout=3s

echo -e "\n\nDescribing pod nginx-pod...\n"

kubectl describe pod nginx-pod

echo -e "\n\nGetting events...\n"

kubectl get events

echo -e "\n\nGetting logs of pod nginx-pod...\n"

kubectl logs nginx-pod

echo -e "\n\nDeleting pods...\n"

kubectl delete pod nginx-pod