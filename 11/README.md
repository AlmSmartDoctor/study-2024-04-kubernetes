# Chapter 8. 클러스터 API, 메타데이터 API, Chapter 11. 메인터넌스와 노드 정지

> 발표일 `24.05.28`
>
> 발표자 `곽재영`
> 
> Chapter 8. 클러스터 API, 메타데이터 API (p.416 - 424)
>
> Chapter 11. 메인터넌스와 노드 정지 (p.506 - p.513)

<br/>

## 클러스터 API 카테고리와 메타데이터 API 카테고리의 개요

|종류|개요|
|:------|:---|
|✅ 워크로드 API 카테고리|컨테이너 실행에 관련된 리소스|
|✅ 서비스 API 카테고리|컨테이너를 외부에 공개하는 엔드포인트를 제공하는 리소스|
|✅ 컨피그 & 스토리지 API 카테고리|설정/기밀 정보/영구 볼륨 등에 관련된 리소스|
|클러스터 API 카테고리|보안이나 쿼터 등에 관련된 리소스|
|메타데이터 API 카테고리|클러스터 내부의 다른 리소스를 관리하기 위한 리소스|

<br/>

**클러스터 API**

클러스터 API 카테고리로 분류된 리소스는 보안 관련 설정이나 쿼터 설정 등 클러스터 동작을 제어하기 위한 리소스.

내부적으로 사용하는 리소스를 제외하고 사용자가 직접 이용할 수 있는 리소스는 다음의 10개이다.

- 노드
- 네임스페이스
- 영구 볼륨 (7장)
- 리소스 쿼터 (9장)
- 서비스 어카운트 (13장)
- 롤 (13장)
- 클러스터롤 (13장)
- 롤바인딩 (13장)
- 클러스터롤바인딩 (13장)
- 네트워크 정책 (13장)

<br/>

**메타데이터 API**

메타데이터 API 카테고리로 분류된 리소스는 클러스터에 컨테이너를 기동하는 데 사용하는 리소스.

내부적으로 사용하는 리소스를 제외하고 사용자가 직접 이용할 수 있는 리소스는 다음의 4개이다.

- LimitRange (9장)
- HorizontalPodAutoscaler (9장)
- PodDisruptionBudget (11장)
- CustomResourceDefinition (19장)

<br/>
  
## 노드

노드 리소스는 기본적으로 사용자가 생성하거나 삭제하는 리소스는 아니지만 쿠버네티스에 리소스로 등록되어 있다.

그렇다고 해서 사용자가 의식하지 않는 리소스라는 의미는 아니며, 쿠버네티스를 운영하면서 자주 확인하는 리소스다.

```sh
# 노드 상세 정보 표시
kubectl get nodes -o wide
```

<br/>

노드 정보를 yaml 파일 형식으로 출력하여 노드에서 어떤 정보를 가져올 수 있는지 확인 가능.

예를 들어 노드 IP 정보와 호스트명은 status.address에 저장되어 있다.

```sh
# 특정 노드 정보를 YAML 형식으로 출력
kubectl get nodes ${NODE_ID} -o yaml

...(생략)...
status:
  addresses:
  - address: 10.178.15.210
    type: InternalIP
...(생략)...
```

<br/>

노드 리소스는 status.allocatable과 status.capacity에서 확인 가능.

```sh
# 특정 노드에 할당된 리소스와 사용 가능한 리소스 확인
kubectl get nodes ${NODE_ID} -o yaml

...(생략)...
status:
  ...(생략)...
  allocatable:
    attachable-volumes-gce-pd: "127"
    cpu: 3920m
    ...
  capacity:
    attachable-volumes-gce-pd: "127"
    cpu: "4"
    ...
...(생략)...
```

<br/>

할당할 수 있는 남은 리소스 양을 확인하려면 Allocatable에서 현재 리소스 사용량을 빼야 한다.

현재 리소스 사용량은 describe node를 통해 확인한다.

```sh
# 특정 노드의 상세 정보 확인
kubectl describe ndoe ${NODE_ID}
```

<br/>

쿠버네티스에서는 노드 상태를 다양한 측면에서 확인하고, 그 모니터링 결과는 쿠버네티스 API에 등록된다.

노드 Status가 Ready가 아닌 경우 status.conditions를 보면 그 원인을 확인할 수 있다.

```sh
kubectl get nodes ${NODE_ID} -o yaml

...(생략)...
status:
  ...(생략)...
  conditions:
  - lastHeartbeatTime: "2021-04-04T02:35:58Z"
    lastTransitionTIme: "2021-04-04T02:25:56Z"
    message: docker overlay2 is fuctioning properly
    reason: NoCorruptDockerOverlay2
    status: "Flase"
...(생략)...
```

<br/>

이 외에도 노드가 소유하고 있는 도커 이미지는 `status.images`에, 노드 버전 등의 정보는 status.nodeInfo에서 확인할 수 있다.

<br/>

여기서 본 정보들은 `kubectl describe node` 명령어로도 대부분 확인할 수 있다.

프로그래밍 내부에서 처리하는 경우에는 `kubectl get nodes -o yaml/json`으로, 터미널에서 직접 눈으로 확인하는 경우에는 `kubectl describe node`로 확인하는 것이 좋다.

<br/>

## 네임스페이스

쿠버네티스에는 네임스페이스라는 가상의 쿠버네티스 클러스터 분리 기능 존재.

초기 상태에서 default/kube-system/kube-public/kube-node-lease의 네 가지 네임스페이스가 생성되며 직접 생성도 가능.

네임스페이스는 리소스의 쿼터를 설정하는 리소스 쿼터나 인증을 수행하는 RBAC에서도 설정 범위를 지정할 때 사용 가능.

<br/>

### 네임스페이스 생성

매니페스트로 생성하는 경우

```yml
apiVersion: v1
kind: Namespace
metadata:
  name: sample-namespace
```

kubectl 커맨드로 생성하는 경우

```sh
kubectl create namespace sample-namespace
```

<br/>

### 네임스페이스를 지정한 리소스 획득

네임스페이스를 지정하여 리소스를 가져오는 경우 -n 또는 --namespace 옵션 사용.

```sh
# sample-namespace의 파드 목록 가져옴
kubectl get pods -n sample-namespace

# 모든 네임스페이스의 파드 목록 가져옴
kubectl get pods --all-namespaces
또는
kubectl get pods -A
```

<br/>

<hr/>

## 노드 정지와 파드 정지

쿠버네티스 노드를 안전하게 정지할 때는 몇 가지 단계를 거쳐야 한다.

메인터넌스 등으로 노드를 정지하는 경우 파드를 정지해야 한다.

SIGTERM, SIGKILL 신호에 동작하는 애플리케이션을 만들고 terminationGracePeriodSeconds를 적절하게 설정해야 하는 것에 유의한다.

<br/>

## 스케줄링 대상에서 제외와 복귀 (cordon/uncordon)

쿠버네티스의 노드는 SchedulingEnabled와 SchedulingDisabled 중 하나의 상태를 가진다.

SchedulingDisabled 상태인 노드는 스케줄링 대상에서 제외되어 노드상에 파드가 신규로 생성되지 않는다.

노드를 SchedulingDisabled 상태로 변경해도 이미 노드에서 실해오디는 파드에는 영향을 주지 않는다.

기본 상태는 SchedulingEnabled이다.

노드를 SchedulingDisabled로 변경하고 스케줄 대상에서 제외하는 경우 cordon 명령어를 사용한다.

```sh
kubectl cordon ${NODE_ID}
```

반대로 SchedulingEnabled로 변경하고 스케줄링 대상으로 돌아가려면 uncordon 명령어를 사용한다.

```sh
kubectl uncordon ${NODE_ID}
```

<br/>

## 노드 배출 처리로 인한 파드 축출 (drain)

상태를 SchedulingDisabled로 변경해도 이후의 스케줄링 대상에서 제외될 뿐이며, 노드에서 이미 실행 중인 파드는 정지되지 않는다.

노드상에 실행 중인 모든 파드를 축출시키는 배출처리를 하려면 drain 명령어를 사용한다.

노드가 배출 처리를 시작하면 노드를 SchedulingDisabled 상태로 변경하고 각 파드에 SIGTERM 신호를 보내어 파드를 축출한다.

이때 스케줄링 대상에서 제외하는 처리도 포함되어 있어 미리 cordon 명령어를 실행할 필요가 없다.

```sh
# 노드에서 실행 중인 파드를 모두 축출 (데몬셋 이외)
kubectl drain ${NODE_ID} --force --ignore-daemonsets
```

<br/>

drain 명령어는 다음과 같은 경우 에러가 발생한다. 다음의 세 가지 경고에 대해서 삭제해도 문제가 없는지 확인한 후에 처리해야 한다.

- pod not managed by ReplicationController, ReplicaSet, Job, DaemonSet or StatefulSet (use --force to override): sample-pod
  - 에러 발생 상황: 디플로이먼트 등으로 관리되지 않은 파드를 삭제하려고할 때
  - 이유: 단일 파드가 있으면 파드 삭제 후에 재생성이 되지 않기 때문에
  - 해결책: --force 옵션을 사용하여 삭제
- pod with local storage (use --delete-local-data to override): sample-pod
  - 에러 발생 상황: 로컬 스토리지를 사용하고 있는 파드를 삭제하려고 할 때
  - 이유: 로컬 스토리지를 사용하고 있는  경우 데이터가 삭제되기 떄문에
  - 해결책: --delete-local-data 옵션을 사용하여 삭제
- DaemonSet-managed pod (use --ignore-daemonsets to ignore): fluentd-gcp-v2.0.10-bwlcp
  - 에러 발생 상황: 데몬셋이 관리하는 파드를 삭제하려고 할 때
  - 이유: 데몬셋이 관리하는 파드는 축출되지 않기 때문에
  - 해결책: --ignore-daemonsets 옵션을 사용하여 삭제

<br/>


## PodDisruptionBudget(PDB)을 사용한 안전한 축출

PodDisruptionBudget은 노드가 배출 처리를 할 떄 파드를 정지할 수 있는 최대 수를 제한하는 리소스다.

파드가 축출될 때 특정 디플로이먼트 관리하에 있는 레플리카가 동시에 모두 정지되면 다운타임이 발생할 수 있다.

또한, 여러 노드에서 동시에 배출 처리를 한 경우에는 이 현상이 발생할 확률이 더욱 높아진다.

따라서 PodDisruptionBudget을 설정해 두면 조건에 일치하는 파드의 최소 기동 개수와 최대 정지 개수를 보면서 노드상에서 파드를 축출할 수 있다.

```yml
apiVersion: policy/v1beta1
kind: PodDisruptionBudget
metadata:
  name: sample-pod-disruption-budget
spec:
  minAvailable: 1
  # maxUnavailable: 1
  selector:
    matchLabels:
      app: sample-app
```

<br/>

PodDisruptionBudget은 메인터넌스에서 동시에 여러 노드를 배출 처리하는 경우에도 효과적이다.

여러 노드에 대해 서비스가 계속 가능하도록 파드 수를 조절하면서 배출하는 것이 어려우므로 한 대 노드씩 배출 처리해 버리기 쉽다.

적은 수의 노드일 경우 문제가 없지만, 대규모 클러스터의 경우 PodDisruptionBudget 없이 효과적으로 진행하기 어렵다.

또한, `minAvailable`과 `maxAvaliable`은 백분율(%)로 설정할 수도 있다.

HorizontalPodAutoscaler에 의해 파드 수가 변화하는 환경에서는 백분율로 지정하는 것을 추천한다.

```yml
apiVersion: policy/v1beta1
kind: PodDisruptionBudget
metadata:
  name: sample-pod-disruption-budget-percentage
spec:
  minAvailable: 90%
  # maxUnavailable: 10%
  selector:
    matchLabels:
      app: sample-app
```

<br/>

파드에 여러 PodDisruptionBudget이 연결된 경우에는 축출 처리가 되지 않고 실패하기 때문에 주의해야 한다.
