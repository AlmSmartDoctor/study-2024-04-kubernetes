# 유연한 스케줄링 Part 2 (12장)

### 10. 여러 조건을 조합한 파드 스케줄링

> 노드 어피니티/노드 안티어피니티/인터파드 어피니티/인터파드 안티어피니티를 조합하여 사용 가능

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: sample-pod-complex-scheduling
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      ~~~
      preferredDuringSchedulingIgnoredDuringExecution:
      ~~~
    podAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      ~~~
    podAntiAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      ~~~
```

### 11. TopologySpreadConstraints를 사용한 토폴로지 균형

- 클러스터는 여러 호스트/리전/존 등의 토폴로지에 걸쳐 구축
- 토폴로지를 의식하고 균등하게 분산 배치하는 스케줄링을 구현하기 위해 TopologySpreadConstraints 도입

##### 같은 존에 한 개 파드보다 많은 편차를 허용하지 않는 스케줄링 예제

```yaml
topologySpreadConstraints:
  - topologyKey: topology.kubernetes.io/zone
    labelSelector:
      matchLabels:
        app: sample-app
    maxSkew: 1
    wehnUnsatisfiable: DoNotSchedule
```

##### 같은 존에 한 개 파드/같은 호스트에 두 개 파드의 편차를 허용하는 스케줄링 예제

```yaml
topologySpreadConstraints:
  - topologyKey: kubernetes.io/hostname
    labelSelector:
      matchLabels:
        app: sample-app
    maxSkew: 2
    wehnUnsatisfiable: DoNotSchedule
  - topologyKey: topology.kubernetes.io/zone
    labelSelector:
      matchLabels:
        app: sample-app
    maxSkew: 1
    wehnUnsatisfiable: DoNotSchedule
```

##### whenUnsatisfiable

> 조건에 대해 만족하지 않을 경우의 동작 설정

- DoNotSchedule(기본값)
  - 조건을 만족하지 않으면 스케줄링 x
- ScheduleAnyway
  - 조건을 만족하지 않아도 우선순위를 부여하여 스케줄링

### 12. 테인트와 톨러레이션

> 노드에 대한 taint를 설정해 두고 그것을 toleration 할 수 있는 파드만 스케줄링을 허가

- 파드가 제시하고 노드가 허가하는 형태
- 대상 노드를 특정 용도를 위한 전용 노드로 사용하는 경우 사용 가능
  - ex) 프로덕션용 노드에 다른 워크로드를 배치하고 싶지 않은 경우
- 조건에 맞지 않는 파드를 노드상에서 축출 가능

#### 12.1 테인트 부여

> Key=Value:Effect 형식으로 구성

- Key와 Value는 임의의 값으로 지정, 일치 여부를 조건으로 사용
- Effect:
  - PreferNoSchedule: 가능한 한 스케줄링하지 않음
  - NoSchedule: 스케줄링하지 않음(이미 스케줄링된 파드는 유지)
  - NoExecute: 실행을 허가하지 않음(이미 스케줄링된 파드는 정지)
- kubectl taint 명령어를 사용
  - kubectl taint nodes {node-name} {key}={value}:{effect}

#### 12.2 톨러레이션을 지정한 파드 기동

> Key/Value/Effect를 지정하고 테인트에서 부여된 Key/Value/Effect가 같은 경우에 허용

- Key/Value/Effect 중 하나를 미지정한 경우 와일드카드
- spec.tolerations로 지정
- Key 조건식 오퍼레이터 종류:
  - Equal: Key와 Value가 같다
  - Exists: Key가 존재한다
- PreferNoSchedule의 경우는 조건이 일치하지 않아도 스케줄링되지만 우선순위가 내려감

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: sample-tolerations
spec:
  containers:
    - name: nginx-container
      image: nginx:1.16
  tolerations:
    - key: "env"
      operator: "Equal"
      value: "prd"
      effect: "NoSchedule"
```

```yaml
tolerations:
  - operator: "Exists"
```

> Exists 오퍼레이터만 지정하면 모든 조건에 일치시킬 수 있음

#### 12.3 NoExecute 일정 시간 허용

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: sample-tolerations-second
spec:
  containers:
    - name: nginx-container
      image: nginx:1.16
  tolerations:
    - key: "env"
      operator: "Equal"
      value: "prd"
      effect: "NoExecute"
      tolerationSeconds: 45
```

#### 12.4 여러 개의 테인트와 톨러레이션

- 노드에는 여러 개의 테인트 부여 가능
- 파드의 톨러레이션은 **모든** 테인트 조건을 만족해야 허용

### 12.5 장애 시 부여되는 테인트와 축출

> 노드에 장애가 발생한 경우 자동으로 NoExecute의 테인트를 부여하여 노드 장애 시 자동으로 파드를 축출하는 기능

| Effect     | Key                            | 개요                                             |
| ---------- | ------------------------------ | ------------------------------------------------ |
| NoExecute | node.kubernetes.io/not-ready   | 노드 상태가 Ready가 아닌 상태(NotReady)          |
| NoExecute | node.kubernetes.io/unreachable | 노드와의 네트워크 접속이 되지 않는 경우(Unknown) |

##### 노드에 장애가 발생해도 파드를 계속 기동하고 싶은 경우

```yaml
tolerations:
  - effect: NoExecute
    key: node.kubernetes.io/not-ready
    operator: Exists
    tolerationSeconds: 300
  - effect: NoExecute
    key: node.kubernetes.io/unreachable
    operator: Exists
    tolerationSeconds: 300
```

### 12.6 쿠버네티스가 부여하는 그 외 테인트

##### 노드에 문제가 발생했을 때

| Effect     | Key                                    | 개요                                      |
| ---------- | -------------------------------------- | ----------------------------------------- |
| NoExecute | node.kubernetes.io/memory-pressure     | 노드에 메모리 부족                        |
| NoExecute | node.kubernetes.io/disk-pressure       | 노드에 디스크 부족                        |
| NoExecute | node.kubernetes.io/pid-pressure        | 노드에 PID 고갈                           |
| NoExecute | node.kubernetes.io/network-unavailable | 노드의 네트워크가 연결되지 않음           |
| NoExecute | node.kubernetes.io/unschedulable       | kubectl cordon에 의해 스케줄링에서 제외됨 |

##### 클라우드 환경에서 노드가 생성되고 삭제될 때

| Effect     | Key                                            | 개요                                                                  |
| ---------- | ---------------------------------------------- | --------------------------------------------------------------------- |
| NoExecute | node.cloudprovider.kubernetes.io/uninitialized | 클라우드 프로바이더에 의해 노드를 처음 기동할 때 초기화되는 것을 대기 |
| NoExecute | node.cloudprovider.kubernetes.io/shutdown      | 클라우드 프로바이더에 의해 노드를 정지할 때 전처리                    |

### 13. PriorityClass를 이용한 파드 우선순위와 축출

- 여러 파드가 스케줄링 대기 상태일 경우 우선순위대로 스케줄링 순서 정렬
- 리소스의 한계까지 스케줄링된 상태에서 우선순위가 더 높은 파드를 생성하려는 경우 기존 파드 축출 가능

#### 13.1 PriorityClass 생성

- 우선순위(value)와 설명(description)으로 구성
- 우선순위 값이 높을수록 먼저 기동 상태 유지

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: sample-priority-class
value: 100
globalDefault: false
description: "used for serviceA only"
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: sample-high-priority
spec:
  containers:
    - name: nginx-container
      image: nginx:1.16
  priorityClassName: sample-priority-class
```

##### 높은 우선순위의 파드에 의해 낮은 우선순위 파드를 축출

![](images/27.png)

##### 인터파드 어피니티와 우선순위 조합에 따른 문제

![](images/28.png)

#### 13.2 우선순위 축출 비활성화

```yaml
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: sample-priority-class-preemption-policy
value: 100
globalDefault: false
description: "used for serviceA only"
preemptionPolicy: Never
```

- preemptionPolicy를 Never로 설정
- 우선순위대로 스케줄링
- 축출 x

#### 13.3 PriorityClass와 PodDisruptionBudget의 경합

> PriorityClass에 의한 축출 처리는 PodDisruptionBudget을 고려하여 스케줄링 하지만 우선순위에 따라 강제로 축출하므로 엄밀하게는 보장 x

### 14. 기타 스케줄링

##### 커스텀 스케줄러를 사용하는 파드 예제

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: sample-custom-scheduler
spec:
  schedulerName: custom-scheduler
  containers:
    - name: nginx-container
      image: nginx:1.16
```

##### 특정 노드를 지정하여 스케줄링하는 파드 예제

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: sample-nodespecific-scheduler
spec:
  nodeName: gke-k8s-default-pool-be722c17-7ij3
  containers:
    - name: nginx-container
      image: nginx:1.16
```
