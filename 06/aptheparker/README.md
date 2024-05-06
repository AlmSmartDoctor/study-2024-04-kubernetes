1. 헬름 파트를 이용해 Nginx 애플리케이션을 설치합니다. 실습을 통해 헬름 애플리케이션 관리의 라이프사이클과 헬름의 3가지 주요 요소인 헬름 차트, 헬렘 리포지토리, 헬름 템플릿의 개념을 이해합니다.

- Install Helm

![Install Helm](./images/install-helm.png)

- Pull Nginx Helm Chart

![Pull Nginx Helm Chart](./images/pull-nginx-helm-chart.png)

- templates/

![templates](./images/templates.png)

- my-values.yaml

![my-values.yaml](./images/my-values.png)

- Install Nginx Helm Chart

![Install Nginx Helm Chart](./images/install-nginx-helm-chart.png)

- Check Nginx Helm Chart

![Check Nginx Helm Chart](./images/check-nginx-helm-chart.png)

![Get deploy,svc,configmap](./images/get-deploy-svc-configmap.png)

2. 헬름 파트의 템플릿 변수 파일을 이용해 파드의 리소스에 대한 Requests/Limits 설정을 변경해서 템플릿 변수 파일의 사용법을 이해합니다.

- mem-limits01-pod.yaml

  ![mem-limits01-pod.yaml](./images/mem-limits01-pod.png)
  ![apply limit pod](./images/apply-limit-pod.png)
  ![CrashLoopBackOff](./images/crashloopbackoff.png)
