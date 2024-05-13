git clone https://github.com/dockersamples/example-voting-app.git

cd example-voting-app

kubectl create ns vote

kubectl apply -f k8s-specifications/ -n vote
