# Chapter 17. 쿠버네티스 환경에서의 CI/CD

> 발표일 `24.06.27`
>
> 발표자 `곽재영`
> 
> Chapter 17. 쿠버네티스 환경에서의 CI/CD (~개발 환경을 정비하는 도구) (p.693 - 729)

<br/>

## 1. 쿠버네티스 환경에서의 CI/CD

실제 운영 환경에서는 휴먼 에러나 규모 확장 등의 문제로 `kubectl` 명령어를 수동으로 실행하는 것을 가능한 피해야 한다.

일반적으로는 자동으로 CI/CD를 수행하는 파이프라인을 구축해서 사용한다.

애플리케이션의 소스 코드, 앤서블(Ansible), 셰프(Chef) 등의 인프라 구성 코드는 깃 저장소에서 관리하는 것이 일반적이다. 기본 방침으로 쿠버네티스의 매니페스트 파일이나 헬름, Kutomize 등의 코드도 깃 저장소에서 관리하도록 한다.

즉, 쿠버네티스에서 CD는 깃 저장소에 저장된 매니페스트 파일을 kubectl 등으로 자동 배포하는 구조를 만들어야 한다.

<br/>

## 2. 깃옵스

깃옵스(GitOps)는 깃(Git)을 사용한 CI/CD 방법 중 하나이다.

깃옵스는 애플리케이션 업데이트, 도커 이미지 변경 같은 쿠버네티스 클러스터 조작을 깃 저장소를 통해 실시하므로 수동으로 매니페스트를 변경하거나 `kubectl apply` 같은 명령어를 실행할 필요가 없다.


쿠버네티스에 배포할 애플리케이션을 개발할 때는 다음과 같은 흐름으로 진행된다.
1. 애플리케이션 소스 코드 변경
2. 애플리케이션 테스트 실시
3. 컨테이너 이미지 생성(애플리케이션 컴파일 포함)
4. 컨테이너 이미지를 컨테이너 레지스트리에 푸시
5. 디플로이먼트 등의 매니페스트를 변경(이미지 태그)
6. kubectl apply와 같은 처리를 실행하여 클러스터에 반영

![CamScanner 06-27-2024 02 24(1)_1](https://github.com/AlmSmartDoctor/study-2024-04-kubernetes/assets/66120479/724b37df-00d6-41d9-b3cd-41d78225580a)

<br/>

## 3. 깃옵스에 적합한 CI 도구

깃옵스를 구현하는 CI 도구는 애플리케이션 테스트, 도커 이미지 빌드, 매니페스트 저장소 업데이트 등과 같은 기본적인 처리를 할 수 있는 것이면 무엇이든지 사용할 수 있다.

쿠버네티스와의 호환성이 높은 도구로는 쿠버네티스의 CustomResource로 CI 파이프라인을 정의 가능한 Tekton이나 쿠버네티스에서 컨테이너를 빌드하는 Kaniko를 선택할 수 있다.

<br/>

## 4. CI 시 쿠버네티스 매니페스트 체크 실시

다음과 같은 소프트웨어를 사용하면 매니페스트 저장소에 잘못된 값이나 구조를 가진 매니페스트, 회사 정책을 위반하는 매니페스트가 포함되는 것을 CI 타이밍에 제거할 수 있다.

### 4.1. 큐비발

큐비발(Kubeval)은 매니페스트 파일의 YAML 구조가 특정 API 버전을 준수하는지 검증할 수 있는 OSS이며, 체크 가능한 리소스는 쿠버네티스 표준으로 사용되는 리소스로 한정한다.

자주 하는 실수로 Annotations 값에는 문자열이나 Null 값이 들어가야되는데 숫자를 지정하는 경우가 있다. 이를 Kubeval로 자료형을 체크해서 사전에 검출할 수 있다.

```sh
$ kubeval ./*.yaml --kubernetes-version 1.18.1
WARN - /fail-deployment.yaml contains an invalid Deployment (fail-deployment) - metadata. annotations: Invalid type. Expected: [string, nulll, given: integer

# Annotations 값에는 문자열 또는 Null 값만 허용되기 때문에 오류가 반환됨
$ cat fail-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: fail-deployment
  annotations:
    max-replicas: 100
  spec:
..(생략)..

```

<br/>

### 4.2. Conftest

Contfest는 매니페스트 파일을 유닛 테스트하는 OSS다.

OpenPolicyAgent에서 사용되는 Rego 언어로 정책을 기술하고 다음과 같은 테스트를 CI 도구에 통합할 수 있다.

- 특수 권한 컨테이너 사용 여부
- 리소스에 부여하는 레이블 룰을 정한 경우 필요한 레이블의 누락 여부
- 이미지 태그가 latest인지 확인
- 리소스 제어에 관한 설정 정의 여부

ex) 디플로이먼트의 파드 템플릿과 셀렉터의 app 레이블이 포함되어 있고 같은 레이블인지 강제
```rego
package main

deny [msg] {
  input. kind == "Deployment"
  not (input. spec. selector.matchLabels. app = input. spec. template.metadata.labels.app)
  msg = sprintf("Pod Template와 Selector에는 같은 app 레이블을 부여해 주세요: 5", [input.
metadata. name ])
}}
```  

<br/>

### 4.3. OpenPolicyAgent/GateKeeper

OpenPolicyAgent 범용 정책을 체크하는 오픈 소스로, 쿠버네티스와 연계하는 GateKeeper와 결합하여 매니페스트가 적용될 때 정책을 체크할 수 있다.

앞에서 나온 Conftest를 사용하고도 CI/CD를 거치지 않고 직접 매니페스트를 쿠버네티스에 등록한 경우 정책 위반이 가능하다.

OpenPolicyAgent/GateKeeper는 쿠버네티스의 Admission Controller로 동작하기 때문에 쿠버네티스 API에 등록된 타이밍에 체크하는 것도 가능하다.

또 GateKeeper는 클러스터에 등록된 리소스도 참조할 수 있기에 인그레스 리소스의 호스트명 충돌 여부나 리소스 간 레이블명 충돌 여부 등을 확인할 수 있다.

더 강력한 정책을 적용하는 경우 Conftest와 Gatekeeper를 모두 사용할 수 있다.

ex) [특정 레이블 강제 예제](https://github.com/open-policy-agent/gatekeeper/blob/master/demo/k8s-validating-admission-policy/k8srequiredlabels_template.yaml)

<br/>

## 5. 깃옵스에 적합한 CD 도구

### 5.1. ArgoCD

ArgoCD는 깃옵스를 구현하기 위한 CD 도구이며, 지정한 저장소를 모니터링하고 쿠버네티스 클러스터에 매니페스트를 적용한다. 그림 17.1의 배포 에이전트에 해당한다.

ArgoCD는 애플리케이션 리소스를 생성하여 특정 저장소의 특정 경로에 있는 파일을 쿠버네티스 클러스터에 적용한 구조이다. 기본적으로 자동으로 동기화되도록 설정하는 것을 권장하지만, 매니페스트 차이점을 확인해야할 경우 수동으로 관리할 수도 있다.

또, 저장소에서 삭제된 리소스를 자동으로 삭제하는 prune 옵션과 자동으로 복구시키는 selfHeal 옵션 등도 있다.

깃 저장소 매니페스트를 동기화하는 예제

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: sample-ca
  namespace: argocd
spec:
  project: default
  # 적용할 매니페스트
  source:
    repoURL: https://github. com/MasayaAoyama/kubernetes-perfect-guide.git
    targetRevision: 2nd-edition
    path: samples/chapter17/argocd/manifests
    directory:
      recurse: true
  # 적용 대상(기본은 자신의 클러스터)
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  # 동기 설정
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

<br/>

### 5.2. 시크릿 리소스의 매니페스트 암호화

시크릿 리소스 매니페스트는 base64로 인코드되어 있을 뿐이며 암호화되어 있지 않아 깃 저장소에 저장할 수 없다.

다양한 방법으로 시크릿 리소스의 매니페스트를 암호화하는 방법에 13장에 있다고 한다. [13주차 발표자료](https://github.com/AlmSmartDoctor/study-2024-04-kubernetes/blob/main/13/README.md#%EC%8B%9C%ED%81%AC%EB%A6%BF-%EB%A6%AC%EC%86%8C%EC%8A%A4-%EC%95%94%ED%98%B8%ED%99%94)

<br/>

## 6. 개발 환경을 정비하는 도구

### 6.1. 텔레프레전스

텔레프레전스(Telepresence)는 원격 쿠버네티스 클러스터를 사용하여 로컬 개발을 구현하는 것으로 CNCF의 Sandbox 프로젝트로 호스트되어 있다.

텔레프레전스는 원격에 있는 쿠버네티스 클러스터에서 전체 구성 요소를 동작시키고 그 중 일부만 로컬에서 동작시키는 구조다.

원격에 있는 쿠버네티스 클러스터와 로컬 머신은 네트워크로 통신할 수 있는 상태로 만들었기 때문에 로컬 머신에서 기동한 컨테이너에서 원격 쿠버네티스 파드 네트워크로 접속할 수 있다.

![CamScanner 06-27-2024 02 24(1)_2](https://github.com/AlmSmartDoctor/study-2024-04-kubernetes/assets/66120479/a9814e62-945d-4737-bb9d-3b570f31dfb2)

[공식문서](https://www.telepresence.io/)

<br/>

### 6.2. 스캐폴드

스캐폴드(Skaffold)는 구글이 개발한 오픈 소스 소프트웨어로, 도커 및 쿠버네티스용 빌드와 배포를 자동화하는 도구다.

일반적으로 애플리케이션 소스 코드에 변경이 발생하면 '컨테이너 이미지 빌드', '컨테이너 이미지 푸시', '쿠버네티스로의 배포'를 해야 하는 이런 과정의 CI/CD 파이프라인을 구성해야 한다.

스캐폴드는 애플리케이션 소스 코드가 변경된 것을 감지하면 도커 이미지 빌드, 도커 레지스트리로 푸시, 쿠버네티스 클러스터로의 배포를 모두 일원화하여 관리할 수 있다.

또, 빌드한 도커 이미지를 레지스트리에 푸시하지 않고 쿠버네티스 클러스터로 배포할 수 있으며, 어느 정도 정해진 타이밍에 도커 이미지를 레지스트리에 푸시할 수 있다.

```sh
skaffold dev # 소스 코드 변경을 감지하여 자동으로 파이프라인을 계속 실행

skaffold run # 한 번만 파이프라인을 실행
```

[공식문서](https://skaffold.dev/)
