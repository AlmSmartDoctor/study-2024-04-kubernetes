cat <<EOF > vote-service.yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app: vote
  name: vote
  namespace: vote
spec:
  type: LoadBalancer
  ports:
  - name: "vote-service"
    port: 80
    targetPort: 80
  selector:
    app: vote
EOF

kubectl apply -f vote-service.yaml