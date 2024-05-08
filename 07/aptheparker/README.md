1. 로드밸런서에 할당할 외부에서 접속 가능한 IP 대역을 지정합니다.

- 노드가 사용하는 IP 대역을 확인.
  ![Node IP](./images/node-ip.png)

- 할당하려는 IP 대역 확인.
  ![IP Range](./images/ip-range.png)

2. 헬름을 이용해 MetalLB를 설치합니다.

- MetalLB repo 추가.
  ![MetalLB Repo](./images/metallb-repo.png)

- MetalLB 설치. (교재 내용은 deprecated 되었으므로 아래와 같이 설치)
  ![MetalLB Install](./images/metallb-install.png)
  ![MetalLB Install](./images/metallb-install-2.png)

3. 테스트 용도의 데모 ‘voting-app’ 애플리케이션을 설치합니다. 프론트엔드 웹에서 사용하는 서비스 타입을 LoadBalancer로 지정합니다. 각 파드에 정상적으로 부하분산이 되는지 확인합니다

- voting-app clone
  ![Voting App Clone](./images/voting-app-clone.png)

- voting-app 실행
  ![Voting App Run](./images/voting-app-run.png)

- Load Balancer 적용
  ![Voting App LoadBalancer](./images/voting-app-loadbalancer.png)

- vote에 LoadBalancer
  ![Voting App Vote](./images/voting-app-vote.png)

- result에 LoadBalancer
  ![Voting App Result](./images/voting-app-result.png)

- 부하분산
  ![Voting App LoadBalancer](./images/voting-app-loadbalancer-2.png)
