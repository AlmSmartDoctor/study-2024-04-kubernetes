# 9장. 리소스 관리와 오토 스케일링

## 목차

1. [리소스 제한](#1-리소스-제한)
2. [Cluster Autoscaler와 리소스 부족](#2-cluster-autoscaler와-리소스-부족)
3. [LimitRange를 사용한 리소스 제한](#3-limitrange를-사용한-리소스-제한)
4. [Qos Class](#4-qos-class)
5. [리소스 쿼터를 사용한 네임스페이스 리소스 쿼터 제한](#5-리소스-쿼터를-사용한-네임스페이스-리소스-쿼터-제한)

## 1. 리소스 제한

### 1.1 CPU/Memory 리소스 제한

- 컨테이너에 리소스 제한을 설정하면 컨테이너가 사용할 수 있는 최대 리소스 양 제한 가능. (CPU, 메모리, Ephermal Storage)
- CPU는 `m`을 사용하여 클럭 수가 아닌 밀리코어(millicore)를 사용.
- 메모리는 `Mi`를 사용하여 메가바이트(MB)를 사용.
- `limits`는 컨테이너가 사용할 수 있는 최대 리소스 양을 제한하는 것이고, `requests`는 컨테이너가 사용할 수 있는 최소 리소스 양을 요청하는 것.

  ```yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: resource-limit
  spec:
    containers:
      - name: resource-limit
        image: busybox
        resources:
          requests:
            memory: "32Mi"
            cpu: "250m"
          limits:
            memory: "64Mi"
            cpu: "500m"
  ```

- 리소스 제한을 설정하지 않으면 컨테이너가 사용할 수 있는 리소스 양이 무제한.

- Request만 설정: 호스트 측 부하가 최대로 상승할 때까지 리소스를 소비하려고 함. -> 리소스 뺏기 발생 (OOM)
- Limit만 설정: 같은 값이 Request에 설정됨.

### 1.2 Ephermal Storage 리소스 제어

- Ephermal Storage는 컨테이너가 사용하는 임시 저장 공간.
  - 컨테이너가 출력하는 로그.
  - emptyDir에 저장되는 데이터.
  - 컨테이너의 쓰기 가능한 레이어에 기록된 데이터.
- kubelet이 컨테이너의 Ephermal Storage 사용량을 모니터링하고, 설정된 제한을 초과하면 컨테이너를 종료시킴. (축출-evict)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-limit
spec:
  containers:
    - name: resource-limit
      image: busybox
      resources:
        limits:
          ephemeral-storage: "1Gi"
```

- 제한된 Ephermal Storage를 초과하면 파드는 `Evicted` 상태가 됨. (P.432)

### 1.3 시스템에 할당된 리소스와 Eviction 매니저

- CPU, 메모리, Ephermal Storage의 일반적인 리소스는 완전히 고갈되면 쿠버네티스 자체가 동작하지 않거나 노드 전체에 영향을 미칠 수 있음. -> 따라서 각 노드는 kube-reserved & system-reserved가 있음.

- kube-reserved: kubelet이 사용하는 리소스.
- system-reserved: 노드의 시스템 프로세스가 사용하는 리소스.

- 쿠버네티스는 파드를 제거하는 Eviction 매니저를 사용하여 리소스 부족 상황을 방지함.

### 1.4 GPU 등의 리소스 제한

- Device Plugin을 사용하면 GPU 등의 다른 리소스도 제한 가능.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-limit
spec:
  containers:
    - name: resource-limit
      image: busybox
      resources:
        limits:
          nvidia.com/gpu: 1
```

### 1.5 오버커밋과 리소스 부족

- 오버커밋: 노드에 있는 리소스보다 더 많은 리소스를 파드에 할당하는 것.
- 리소스 부족: 노드에 있는 리소스보다 더 많은 리소스를 요청하는 것.

- 파드의 Request만큼의 리소스가 없고, 부하가 높아지면 오버커밋하여 실행.

### 1.6 여러 컨테이너 사용 시 리소스 할당

- 파드에 여러 컨테이너가 있을 때, 각 컨테이너의 리소스 요청을 합산하여 파드의 리소스 요청을 계산함.
- 필요한 리소스 양: max(sum(containers[*]), max(initContainers[*]))

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: resource-limit
spec:
  containers:
    - name: resource-limit
      image: busybox
      resources:
        requests:
          memory: "32Mi"
          cpu: "250m"
        limits:
          memory: "64Mi"
          cpu: "500m"
    - name: resource-limit2
      image: busybox
      resources:
        requests:
          memory: "32Mi"
          cpu: "250m"
        limits:
          memory: "64Mi"
          cpu: "500m"
  initContainers:
    - name: resource-limit3
      image: busybox
      resources:
        requests:
          memory: "32Mi"
          cpu: "250m"
        limits:
          memory: "64Mi"
          cpu: "800m"
    - name: resource-limit4
      image: busybox
      resources:
        requests:
          memory: "32Mi"
          cpu: "250m"
        limits:
          memory: "64Mi"
          cpu: "800m"
```

- 위의 경우, 파드의 Request는 `memory: 64Mi`, `cpu: 500m`, Limit은 `memory: 128Mi`, `cpu: 800m`이 됨.

## 2. Cluster Autoscaler와 리소스 부족

- Cluster Autoscaler: 수요에 따라 쿠버네티스 클러스터의 노드 수를 자동으로 추가하는 기능.
- 각 노드의 부하 평균이 아닌, Pending 상태의 파드를 기준으로 노드를 추가함.

  - Requests를 초과하여 할당하면 최소 리소스 요청만으로 리소스가 꽉 차서 신규 노드를 추가해야만 함.
  - 반대로 부하가 높아도 Pending 상태가 없으면 스케줄링이 가능하므로 노드를 추가하지 않음.

- 'Horizontal Pod Autoscaler': 파드의 수요에 따라 파드의 수를 자동으로 조정하는 기능.

  - 파드의 수요가 높아지면 파드를 추가하고, 낮아지면 파드를 제거함.

- 'Vertical Pod Autoscaler': 파드의 리소스 요청을 자동으로 조정하는 기능.

  - 파드의 리소스 요청이 높아지면 리소스 요청을 늘리고, 낮아지면 리소스 요청을 줄임.

## 3. LimitRange를 사용한 리소스 제한

- LimitRange: 네임스페이스에 있는 파드/컨테이너/영구 볼륨에 대한 리소스 제한을 설정하는 오브젝트.

- `default`: 기본 Limits.
- `defaultRequest`: 기본 Requests.
- `max`: 최대 리소스.
- `min`: 최소 리소스.
- `maxLimitRequestRatio`: Limit와 Request의 비율.

### 3.1 컨테이너에 대한 LimitRange

- default/defaultRequest/max/min/maxLimitRequestRatio를 설정하여 LimitRange를 생성함.

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: limit-range
  namespace: default
spec:
  limits:
    - type: Container
      default:
        memory: 64Mi
        cpu: 500m
      defaultRequest:
        memory: 32Mi
        cpu: 250m
      max:
        memory: 128Mi
        cpu: 800m
      min:
        memory: 16Mi
        cpu: 100m
      maxLimitRequestRatio:
        memory: 2
        cpu: 4
```

### 3.2 파드에 대한 LimitRange

- max/min/maxLimitRequestRatio를 설정하여 LimitRange를 생성함.

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: limit-range
  namespace: default
spec:
  limits:
    - type: Pod
      max:
        memory: 128Mi
        cpu: 800m
      min:
        memory: 16Mi
        cpu: 100m
      maxLimitRequestRatio:
        memory: 2
        cpu: 4
```

### 3.3 영구 볼륨 클레임에 대한 LimitRange

- max/min를 설정하여 LimitRange를 생성함.

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: limit-range
  namespace: default
spec:
  limits:
    - type: PersistentVolumeClaim
      max:
        storage: 1Gi
      min:
        storage: 1Gi
```

## 4. Qos Class

- Qos Class: 파드의 리소스 요청과 제한에 따라 파드의 우선 순위를 결정하는 클래스.

- Guaranteed: Request와 Limit이 같고, CPU와 메모리가 설정되어 있음. (최우선 순위)
- Burstable: Guaranteed를 충족하지 못하고, 한 개 이상의 Request와 Limit이 설정되어 있음. (중간 순위)
- BestEffort: Request와 Limit이 없음. (최하위 순위)

### 4.1 Guaranteed

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: qos-class
spec:
  containers:
    - name: qos-class
      image: busybox
      resources:
        requests:
          memory: "32Mi"
          cpu: "250m"
        limits:
          memory: "32Mi"
          cpu: "250m"
```

### 4.2 Burstable

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: qos-class
spec:
  containers:
    - name: qos-class
      image: busybox
      resources:
        requests:
          memory: "32Mi"
          cpu: "250m"
        limits:
          memory: "64Mi"
          cpu: "500m"
```

### 4.3 BestEffort

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: qos-class
spec:
  containers:
    - name: qos-class
      image: busybox
```

## 5. 리소스 쿼터를 사용한 네임스페이스 리소스 쿼터 제한

- ResourceQuota: 각 네임스페이스에 있는 리소스 제한을 설정하는 오브젝트.

- '생성 가능한 리소스 수'와 '리소스 사용량 제한'을 설정함.

- `hard`: 최대 리소스 제한.
- `used`: 사용 중인 리소스 양.

### 5.1 생성 가능한 리소스 수 제한

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: resource-quota
  namespace: default
spec:
  hard:
    count/deployments.apps: 10
    count/services: 5
    count/secrets: 5
```

### 5.2 리소스 사용량 제한

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: resource-quota
  namespace: default
spec:
  hard:
    requests.cpu: 1
    requests.memory: 1Gi
    limits.cpu: 2
    limits.memory: 2Gi
```
