# Chapter 4. API 리소스와 kubectl

> 발표일 `24.04.25`
>
> 발표자 `곽재영`
> 
> Chapter 4. API 리소스와 kubectl (p.89 - 162)
>
> Chapter 2. 효율적인 쿠버네티스 클러스터 관리를 위한 kubectl CLI 환경 최적화 (p.22 - 34)

<br/>

## 쿠버네티스

쿠버네티스는 쿠버네티스 마스터와 쿠버네티스 노드로 구성된다.

쿠버네티스 마스터는 API 엔드포인트 제공, 컨테이너 스케줄링, 컨테이너 스케일링을 담당하는 노드이다.

쿠버네티스 노드는 도커 호스트에 해당하며 실제로 컨테이너를 기동시키는 노드이다.

![image](https://github.com/AlmSmartDoctor/study-2024-04-kubernetes/assets/66120479/3cf2ba95-4f51-41e9-aa04-35e8bc7883b0)

쿠버네티스 클러스터를 관리할 시 CLI 도구인 `kubectl`과 YAML형식 등으로 작성한 매니페스트 파일을 사용하여 쿠버네티스 마스터에 **리소스**를 등록해야한다.

kubectl은 매니페스트 파일 정보를 바탕으로 쿠버네티스 마스터가 가진 API에 요청을 보내어 쿠버네티스를 관리한다.

쿠버네티스 API는 일반적으로 RESTful API로 구현되어있다.

<br/>

## 쿠버네티스와 리소스

쿠버네티스의 리소스는 크게 다섯 가지 카테고리로 분류되며 이러한 리소스 등록을 비동기로 처리할 수 있다.

|종류|개요|
|:------|:---|
|워크로드 API 카테고리|컨테이너 실행에 관련된 리소스|
|서비스 API 카테고리|컨테이너를 외부에 공개하는 엔드포인트를 제공하는 리소스|
|컨피그 & 스토리지 API 카테고리|설정/기밀 정보/영구 볼륨 등에 관련된 리소스|
|클러스터 API 카테고리|보안이나 쿼터 등에 관련된 리소스|
|메타데이터 API 카테고리|클러스터 내부의 다른 리소스를 관리하기 위한 리소스|

이 중 개발자는 워크로드, 서비스, 컨피그 & 스토리지를 주로 사용한다.

**워크로드**
- 파드
- 레플리케이션 컨트롤러
- 레플리카셋
- ...

**서비스**
- 서비스
  - ClusterIP
  - ExternalIP
  - NodePort
  - ...
- 인그레스

**컨피그 & 스토리지**
- 시크릿
- 컨피그맵
- 영구 볼륨 클레임

**클러스터**
- 노드
- 네임스페이스
- 영구 볼륨
- ...

**메타데이터**
- LimitRange
- HorizontalPodAudoscaler
- PodDisruptionBudget
- ...

<br/>

## 네임스페이스로 가상적인 클러스터 분리

네임스페이스: 가상적인 쿠버네티스 클러스터 분리 기능이다.

-> 완전한 분리 개념은 아니어서 용도는 제한되지만, 하나의 클러스터를 여러팀에서 사용하거나 서비스 환경/스테이징 환경/개발 환경으로 구분하는 경우 사용 가능하다.

기본 설정에는 다음 네 가지 네임스페이스가 생성된다.

- kube-system
  - 쿠버네티스 클러스터 구성 요소(대시보드 등)와 애드온이 배포될 네임스페이스
- kube-public
  - 모든 사용자가 사용할 수 있는 컨피그맵 등을 배치하는 네임스페이스
- kube-node-lease
  - 노드 하트비트 정보가 저장된 네임스페이스
- default
  - 기본 네임스페이스

관리형 서비스나 구축 도구로 구축된 경우 대부분의 쿠버네티스 클러스터는 RBAC(Role-Based Access Control)가 기본값으로 활성화되어 있다.

네임스페이스와 RABC를 함께 사용하여 분리성을 높일 수 있다.

<img width="723" alt="image" src="https://github.com/AlmSmartDoctor/study-2024-04-kubernetes/assets/66120479/f6112ddb-a486-4036-85e7-9f0e10bc2a69">

<br/>

## 커맨드 라인 인터페이스 도구 kubectl

[커맨드 모음](https://kubernetes.io/ko/docs/reference/kubectl/#%EB%AA%85%EB%A0%B9%EC%96%B4)

### 인증 정보와 컨텍스트(config)

kubectl이 쿠버네티스 마스터와 통신할 때는 접속 대상의 서버 정보, 인증 정보 등이 필요하다.

kubectl은 kubeconfig에 쓰여 있는 정보를 사용하여 접속한다.

```
apiVersion: v1
kind: Config
preferences: {}
clusters:
  - name: sample-cluster
    cluster:
      server: https://localhost:6443
users:
  - name: sample-user
    user:
      client-certificate-data: LS0tLS1CRUdJTi...
      client-key-data: LS0tLS1CRUdJTi...
contexts:
  - name: sample-context
    context:
      cluster: sample-cluster
      namespace: default
      user: sample-user
current-context: sample-context
```

kubeconfig에서 중요한 부분은 clusters/users/contexts 세 가지이다. 모두 배열로 되어 있어 여러 대상 등록이 가능하다.

- clusters: 접속 대상 클러스터 정보
- users: 인증 정보
- contexts: cluster와 user, 네임스페이스를 지정한 것을 정의

kubeconfig 설정을 변경하려면 직접 편집하는 방법 외에 kubectl 명령어를 사용할 수 있다.

```sh
# 클러스터
kubectl config set-cluster ...

# 인증 정보
kubectl config set-credentials ...

# 컨텍스트
kubectl config set-context ...
```

kubectl은 컨텍스트를 전환하여 여러 환경을 여러 권한으로 조작할 수 있다.

```sh
# 컨텍스트 목록 표시
kubectl config get-contexts

# 컨텍스트 전환
kubectl config use-context ...

# 현재 컨텍스트 표시
kubectl config current-context ...
```

<br/>

### kubectx/kubens를 사용한 전환

> 실습에서 직접 확인 가능

컨텍스트나 네임스페이스를 전환할 때 kubectl 명령어를 사용하는 대신 간편하게 사용할 수 있는 오픈 소스이다.

```sh
# 컨텍스트 전환
kubectx ...
kubectl config use-context ... // 위와 같다

# 네임스페이스 전환 
kubens ...
kubectl config set-context ... // 위와 같다

# 바로 전 컨텍스트로 전환
kubectx -

# 컨텍스트 삭제
kubectx -d ...
```

<br/>

### 매니페스트와 리소스 생성/삭제/갱신

```sh
# 리소스 생성
kubectl create -f {file_name}

# 생성한 파드 목록 표시
kubectl get pods

# 생성한 파드 삭제
kubectl delete -f {file_name}
```

```sh
# 특정 리소스 종류와 리소스 이름으로 삭제
kubectl delete pod {pod_name}

# 특정 리소스 종류 모두 삭제
kubectl delete pod -all
```

kubectl 명령어 실행은 바로 완료되지만, 실제 리소스 처리는 비동기로 실행된다.

--wait 옵션을 사용하여 리소스의 삭제 완료를 기다릴 수 있다.

반대로, 리소스를 강제로 즉시 삭제하는 방법도 있다.

```sh
# 리소스 삭제 대기
kubectl delete -f {file_name} --wait

# 리소스 즉시 강제 삭제
kubectl delete -f {file_name} --grace-period 0 --force
```

리소스 업데이트를 할 때 사용하는 apply는 리소스를 생성할 때도 사용할 수 있다.

apply로 변경할 수 없는 필드가 존재할 수도 있다.

```sh
kubectl apply -f {file_name}
```

<br/>

### 리소스 생성에도 kubectl apply를 사용해야 하는 이유

- 굳이 생성에는 create, 업데이트에는 apply로 나눠서 사용할 필요가 없다.
- create와 apply를 섞어서 사용하면 apply를 실행할 때 변경사항을 검출하지 못할 경우가 있기 때문이다.

-> 따라서 create가 아니라 항상 apply를 쓰는 것을 추천한다고 한다.

<br/>

### 파드 재기동

디플로이먼트 등의 리소스와 연결되어 있는 모든 파드를 재기동할 수 있다.

파드 기동 시 처리를 재실행하고 싶을 때나 시크릿 리소스에서 참조되는 환경 변수를 변경하고 싶을 때 사용하면 좋다.

그러나 리소스와 연결되어 있지 않은 단독 파드에는 사용할 수 없다.

```sh
# 리소스 생성
kubectl apply -f sample-deployment.yml
kubectl apply -f sample-pod.yml

# Deployment 리소스의 모든 파드 재기동
kubectl rollout restart deployment sample-deployment

# 파드는 재기동 안 됨
kubectl rollout restart pod sample-pod // error
```

<br/>

### generateName으로 임의의 이름을 가진 리소스 생성

create를 사용하여 난수가 있는 이름의 리소스를 생성할 수 있다.

metadata.name 대신 metadata.generateName을 지정하면 그것을 prefix로 가지는 이름이 자동으로 생성된다.

```yml
apiVersion: v1
kind: Pod
metadata:
  generateName: sample-generatename-
spec:
  ...
```

```sh
kubectl create -f sample-generatename.yml

# pod/sample-generatename-n2jpz
# pod/sample-generatename-6km7c
# pod/sample-generatename-z6s4w
```

<br/>

### 리소스 상태 체크와 대기

명령어를 연속적으로 실행할 때 다음 명령어를 실행하기 전 리소스가 의도한 상태가 되기까지 기다려야 할 경우 wait 명령어를 사용할 수 있다.

--for 옵션에 지정한 상태가 되기까지 기다리며, 최대 --timeout 옵션(기본값 30초)에 지정한 시간까지 대기한다.

```sh
# sample-pod이 정상적으로 기동할 때까지 대기
kubectl wait --for=condition=Ready pad/sample-pod

# 모든 파드가 스케줄링될 때까지 대기
kubectl wait --for=condition=PodScheduled pod -all

# 모든 파드가 삭제될 때까지 최대 5초씩 대기
kubectl wait --for=delete pod --all --timeout=5s
```

<br/>

### 매니페스트 파일 설계

한 개의 매니페스트 파일에 여러 리소스를 정의하거나 여러 매니페스트 파일을 동시에 적용할 수도 있다.

**하나의 매니페스트 파일에 여러 리소스**

`---`로 구분하여 작성한다. 위에서부터 순서대로 적용된다.

```yml
---
apiVersion: v1
kind: Deployment
metadata:
  name: ...
---
apiVersion: v1
kind: Service
metadata:
  name: ...
```

**여러 매니페스트 파일 동시 적용**

디렉토리 이름을 넘겨주어 여러 파일을 적용할 수 있다. 순서를 제어하고 싶을 때는 파일명 앞에 인덱스 번호를 지정하면 된다.

```sh
kubectl apply -f ./dir

# 디렉토리 내부 재귀적으로 적용
kubectl apply -f ./dir -R
```

**매니페스트 파일 설계 방침**

- 시스템 전체를 한 개의 디렉터리로 통합하는 패턴
- 시스템 전체를 특정 서브 시스템으로 분리하는 패턴
- 마이크로서비스별로 디렉터리를 나누는 패턴

<br/>

### 어노테이션과 레이블

각 리소스에 대해 어노테이션과 레이블이라는 메타데이터를 부여할 수 있다.

- 어노테이션: 시스템 구성 요소가 사용하는 메타데이터
  - 시스템 구성 요소를 위한 데이터 저장
  - 모든 환경에서 사용할 수없는 설정
  - 정식으로 통합되기 전의 기능을 설정
- 레이블: 리소스 관리에 사용하는 메타데이터
  - 개발자가 사용하는 레이블
  - 시스템이 사용하는 레이블

매니페스트 파일에 작성할 수도 있지만 커맨드를 사용해서도 할 수 있다.

```sh
# 어노테이션 부여
kubectl annotate pods sample-annotations annotation3=val3

# 덮어 쓰기 허용
kubectl annotate pods sample-annotations annotation3=val3-new --overwrite

# 어노테이션 삭제
kubectl annotate pods sample-annotations annotation3-
```

```sh
# 레이블 부여
kubectl label pods sample-label label3=val3

# 덮어 쓰기 허용
kubectl label pods sample-label label3=val3-new --overwrite

# 레이블 삭제
kubectl label pods sample-label label3-
```

<br/>

### 편집기로 편집: edit

edit 명령어를 통해 편집기 상에서 변경 작업을 할 수 있다.

```sh
# 환경변수에 에디터 정의
export EDITOR=vim

kubectl edit pod sample-pod
```

<br/>

### 리소스 일부 정보 업데이트: set

set 명령어를 통해 매니페스트 파일을 업데이트하지 않고 일부 설정값만 간단히 동작 상태를 변경할 수 있다.

set으로 변경 가능한 설정값은 다음과 같다.

- env
- image
- resources
- selector
- serviceaccount
- subject

```sh
# 컨테이너 이미지 변경
kubectl set image pod sample-pod nginx-container=nginx=1.16
```

set 명령어로 직접 설정을 변경하더라고 가지고 있는 매니페스트 파일은 업데이트되지 않는다.

매니페스트 파일 내용과 서버상의 리소스 상태가 달라지게 되므로 이 기능을 남용하면 안된다.

<br/>

### 로컬 매니페스트와 쿠버네티스 등록 정보 비교 출력: diff

앞에서의 set을 통해 매니페스트 파일을 업데이트 하지 않고 설정을 변경했을 때의 얼마나 차이가 나는지 확인하는 용도로 사용할 수 있다.

```sh
kubectl diff -f {file_name}
```

<br/>

### 사용 가능한 리소스 종류의 목록 가져오기: api-resources

파드나 서비스 등 다양한 종류의 사용 가능한 리소스 목록을 가져온다.

```sh
# 모든 리소스 종류 표시
kubectl api-resources
```

<br/>

### 리소스 정보 가져오기: get

```sh
# 파드 목록 표시
kubectl get pods

# 특정 파드만 표시
kubectl get pods sample-pod

# 노드 목록 표시
kubectl get nodes
```
그외에 필터링이나 보기 옵션이 굉장히 다양하므로 공식문서를 참고하면 좋을듯하다.

<br/>

### 리소스 상세 정보 가져오기: describe

특정 리소스의 정보 중에서 get으로 얻을 수 있는 정보 외의 리소스 관려 이벤트 등과 같은 더 상세한 정보를 확인할 수 있다.

볼륨 셋업, 이미지 다운로드 상태, 컨테이너 라이프사이클, 여유 리소스, 기동 중인 파드 리소스 사용량(노드의 경우) 등이 표시된다.

```sh
kubectl describe pod sample-pod
```

<br/>

### 실제 리소스 사용량 확인: top

describe 명령어로 확인할 수 있는 리소스 사용량은 쿠버네티스가 파드에 확보한 값을 나타낸다.

실제 파드 내부의 컨테이너가 사용하는 리소스 사용량은 top 명령어를 사용하여 확인할 수 있다.

또, top 명령어는 metrics-server(오픈소스 리소스 모니터링 도구)라는 추가 구성 요소를 사용한다.

```sh
# 노드 리소스 사용량 확인
kubectl top node

# 파드별 리소스 사용량 확인
kubectl -n kube-system top pod
```

<br/>

### 컨테이너에서 명령어 실행: exec

exec 명령어를 사용하여 /bin/bash 등의 셸을 실행함으로써 마치 컨테이너에 로그인한 것과 같은 상태를 만들 수 있다.

-t 옵션으로 가상 터미널을 생성하고, -i 옵션으로 표준 입출력을 할 수 있다.

```sh
# 파드 내부의 컨테이너에서 /bin/ls 실행
kubectl exec -it sample-pod -- /bin/ls
```

<br/>

### 로컬 머신에서 파드로 포트 포워딩: port-forward

디버깅 용도 등으로 JMX 클라이언트에서 컨테이너에서 실행 중인 자바 애플리케이션 서버에 접속하거나, 데이터베이스 클라이언트에서 컨테이너에서 기동 중인 MySQL 서버에 접속해야할 경우가 있다.

이때, port-forward 명령어를 사용하여 로컬 머신에서 특정 파드로 트래픽을 전송할 수 있다.

```sh
# localhost:8888에서 파드의 80/TCP 포트로 전송
kubectl port-forward sample-pod 8888:80
```

<br/>

### 컨테이너 로그 확인: logs

컨테이너에서 기동하는 애플리케이션은 표준 출력과 표준 에러 출력으로 로그를 출력하는 것이 좋다.

왜냐하면 logs 명령어를 통해 확인할 수있기 떄문이다.

```sh
# 파드 내의 컨테이너 로그 출력
kubectl logs sample-pod

# 실시간 로그 출력
kubectl logs -f sample-pod

# 최근 1시간 이내, 10건의 로그를 타임스탬프와 함께 출력
kubectl logs --since=1h --tail=10 --timestamps=true sample-pod
```

<br/>

### 스턴을 사용한 로그 확인

오픈 소스인 스턴(Stern)을 사용하면 로그를 더 편리하게 출력할 수 있다.

스턴은 kubectl logs로 할 수 있는 모든 작업이 가능하고, 추가로 다음과 같은 편리한 기능을 제공한다.

- 각 컨테이너 로그를 시계열로 표시
- 타임스탬프 표시(--timestamp 옵션)
- 특정 레이블로 지정한 파드 로그만 표시(--selector 옵션)
- 예외 처리할 로그를 정규 표현식으로 지정 가능 (--exclude 옵션)

<br/>

### 컨테이너와 로컬 머신 간의 파일 복사: cp

cp 명령어를 사용해 컨테이너와 로컬 머신 간 파일 복사를 할 수 있다.

컨테이너에서 로컬 머신, 혹은 로컬 머신에서 컨테이너로의 양방향 복사가 가능하다.

```sh
# sample-pod의 /etc/hostname 파일을 로컬 머신에 복사
kubectl cp sample-pod:etc/hostname ./hostname

# 로컬 파일을 컨테이너로 복사
kubectl cp hostname sample-pod:/tmp/newfile
```

<br/>

### kubectl 플러그인과 패키지 관리자: plugin/krew

> 실습에서 직접 확인 가능

krew라는 플러그인 관리자를 통해 플러그인을 관리할 수 있다.

설치된 플러그인 목록은 plugin 명령어로 확인할 수 있다.

```sh
# krew로 플러그인 설치
kubectl krew install ...

# 설치된 플러그인 목록 표시
kubectl plugin list
```

<br/>

### kubectl의 기타 팁

**alias 생성**

> 실습에서 직접 확인 가능

```sh
alias k='kubectl'

# 짧은 커맨드로 명령어 실행 가능
k get po
```

**kube-ps1**

kube-ps1은 현재 작업 중인 쿠버네티스 클러스터와 네임스페이스를 표시한다.

kubeon으로 기능을 활성화하고, kubeoff로 비활성화할 수 있다.

여러 클러스터나 여러 네임스페이스를 이동하며 조작할 때 실수를 줄일 수 있다.

![image](https://github.com/AlmSmartDoctor/study-2024-04-kubernetes/assets/66120479/5d43a77b-3246-405f-b314-7178145a6535)

