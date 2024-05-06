cat <<EOF > memory-test.yaml
apiVersion: v1
kind: Pod
metadata:
    name: memory-test
    labels:
        app: memory-test
spec:
    containers:
    - name: memory-test
      image: polinux/stress
      resources:
        limits:
            memory: "2Gi"
        requests:
            memory: "1Gi"
      command: ["stress"]
      args: ["--vm", "1", "--vm-bytes", "2500M", "--vm-hang", "1"]
EOF

kubectl apply -f memory-test.yaml