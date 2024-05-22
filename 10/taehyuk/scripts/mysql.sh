helm pull bitnami/mysql

tar xvfz mysql-10.3.0.tgz

cd mysql

cp values.yaml my-values.yaml

k create ns mysql

helm install mysql -f my-values.yaml . -n mysql

