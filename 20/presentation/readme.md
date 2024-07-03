# 17.7 스피네이커

- 관리 도구로 헬리야드 제공
  - 여러 요소로 구성되어 수동으로 설치하기 까다로움

1. 헬리야드 설치
2. 스피네이커 구성요소를 배포할 네임스페이스와 스피네이커가 사용할 서비스 어카운트 생성
3. GCS(S3, Redis, Azure Storage etc...) IAM의 서비스 어카운트 생성
4. 스토리지에 버킷을 생성하고 파이프라인 데이터 저장
5. 스피네이커와 연계할 도커 레지스트리에 저장소를 만들고 이미지 푸시
6. 쿠버네티스에 스피네이커 배포

## 시작

1. 스피네이커 어플리케이션 생성
2. 스피네이커 어플리케이션에서 이용할 로드 밸런서 생성

- 쿠버네티스의 서비스 리소스를 의미
- Stack : myservice
- Port : 80
- Target Port : 8080
- Type : LoadBalancer

3. 서버 그룹 생성

- 쿠버네티스의 디플로이먼트 리소스를 의미
- stack : Mydeployment
- containers : index.docker.io/DOCKERHUB_USER/sample-image:0.1
- Deployment : True
- Capacity : 3

서버 그룹 생성 후 약 1분 뒤에 쿠버네티스에 첫 배포가 완료된다.
실제 파드 상태를 보면 세 레플리카의 파드를 확인할 수 있다.

4. CD 파이프라인 구성

- Type : Docker Registry
- Registry Name : my-registry
- Organization : DOCKERHUB_USER
- Image : DOCKERHUB_USER/sample-image
- Tag : 0.\*
- Trigger Enabled : True

5. 파이프라인이 호출되었을 때 배포할 디플로이먼트 리소스를 정의

6. 도커 허브에 푸시되면 스피네이커 파이프라인이 동작한다.

# 17.8 젠킨스 X

쿠버네티스 + 도커 + 깃 환경을 전제로 한 젠킨스 파생 프로젝트의 오픈소스 소프트웨어
설치는 jx를 이용하고 맥은 brew에서 jx 설치 가능

## 시작

젠킨스 X의 퀵 스타트 기능을 사용해 샘플 어플리케이션으로 개발을 시작 가능

1. 깃헙 저장소가 생성됨

- 어플리케이션 소스 코드, 도커파일, 젠킨스 파일, skaffold.yaml 포함됨

2. 어플리케이션 생성 후 자동으로 CI 수행되고 스테이징 환경에 배포됨
   jx get activity -w 로 확인가능
3. 스테이징 환경의 디플로이먼트와 서비스 배포됨

기본 설정에서는 프로덕션 환경 배포는 수동으로 가능

1. 명령어 실행

```shell
jx promote {application} --env {env} --version {version}
```

2. 네임스페이스에 생성된 디플로이먼트, 서비스 리소스 확인

```shell
kubectl -n jx-production get deployments, services
```
