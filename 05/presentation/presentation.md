# 5.5. 데몬셋

- 레플리카셋의 특수한 형태

| .               | 레플리카셋 | 데몬셋                                        |
| --------------- | ---------- | --------------------------------------------- |
| 노드 당 파드 수 | N          | 1 or 0 (nodeSelector, 안티어피니티 예외 처리) |

- 노드 증가 -> 생성된 노드에서 자동으로 데몬셋 파드 기동
- -> 노드 단위 동작 프로세스에 사용
  - Fluentd(호스트 단위 로드 수집), 노드 모니터링(Datadog)

## 5.5.1. 데몬셋 생성

**추천: vsc kubernetes templates extension**

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: sample-ds
spec:
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app
    spec:
      containers:
        - name: nginx-container
          image: nginx:1.16
```

> two nodes
> ![alt text](image-4.png)

```bash
kubectl apply -f sample-ds.yaml # 데몬셋 생성
```

> two daemonset pods
> ![alt text](image-5.png)

> 노드 추가 -> 3개
> ![alt text](image-7.png)

> 추가된 노드에 데몬셋 파드 자동 기동
> ![alt text](image-6.png)

## 5.5.2. 데몬셋 업데이트 전략

### 5.5.2.1. On Delete

- 메니페스트 수정하더라도 기존 파드 업데이트 하지 않음
- 파드가 삭제되었다가 재생성될 시에 새로운 메니페스트로 업데이트 됨 혹은 수동으로 삭제하여 업데이트 가능

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: sample-ds-ondelete
spec:
  updateStrategy:
    type: OnDelete
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app # app to be updated
    spec:
      containers:
        - name: nginx-container
          image: nginx:1.16
```

데몬셋 템플릿 업데이트 후 아래와 같이 수동으로 파드 삭제시 하나의 파드만 업데이트된 버전으로 재생성됨

```bash
kubectl delete pod [pod-name]
```

### 5.5.2.2. Rolling Update

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: sample-ds-ondelete
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 2 # 파드 한 번에 두 개씩 업데이트
  selector:
    matchLabels:
      app: sample-app
  template:
    metadata:
      labels:
        app: sample-app # app to be updated
    spec:
      containers:
        - name: nginx-container
          image: nginx:1.16
```

# 5.6. 스테이트풀셀

- db와 같이 stateful한 워크로드에 사용하기 위한 레플리카셋의 특수한 형태

레플리카셋과의 차이

- 파드명 뒤에 인덱스 붙음
  - sample-statefulset-0, sample-statefulset-1 ...
- 파드명 불변
- 데이터를 영구적으로 저장하는 구조
  - 영구 볼륨 사용하면 파드 재기동 시에 같은 디스크를 사용하여 생성

## 5.6.1. 스테이트풀셋 생성

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: sample-ss
spec:
  selector:
    matchLabels:
      app: sample-app # has to match .spec.template.metadata.labels
  serviceName: sample-ss
  replicas: 3 # by default is 1
  template:
    metadata:
      labels:
        app: sample-app # has to match .spec.selector.matchLabels
    spec:
      containers:
        - name: nginx-container
          image: nginx:1.16
          volumeMounts:
            - name: www
              mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
    - metadata:
        name: www
      spec:
        accessModes: ["ReadWriteOnce"]
        resources:
          requests:
            storage: 1G
```

![alt text](image-8.png)

![alt text](image-9.png)

> suffix: index

## 5.6.2. 스테이트풀셋 스케일링

```bash
# 메니페스트 수정-적용하여 스케일링
$ sed -i -e 's|replicas: 3|replicas:4' sample-ss.yaml
$ kubectl apply -f sample-ss.yaml

# kubectl scale 이용
$ kubectl scale statefulset sample-ss --replicas=5 # or kubectl scale statefulset.apps sample-ss --replicas=5
```

- Scale Out
  - index 작은 순
  - 하나씩 생성 - 생성한 파드가 Ready 상태가 되면 다음 파드 생성
- Scale In

  - index 큰 순

> 레플리카셋의 경우 무작위로 파드 삭제하기 때문에 특정 파드가 마스터인 경우 문제 발생. 스테이트풀셋의 경우 0번 파드를 마스터 노드로 사용하면 가장 먼저 생성되고 가장 나중에 삭제되기 때문에 이중화 구조 애플리케이션에 적합하다

## 5.6.3. 스테이트풀셋의 라이프사이클

- spec.podManagementPolicy
  - OrderedReady가 default
  - Parallel로 설정하면 레플리카셋과 같이 병렬적으로 동시에 파드가 기동

## 5.6.4. 스테이트풀셋 업데이트 전략

- OnDelete
- RollingUpdate

### Rolling Update

- 영속성 데이터가 있기 때문에 디플로이먼트와 다르게 추가 파드를 생성하서 롤링 업데이트 불가
- 파드마다 Ready 상태인지 체크하고 하나씩 업데이트
  - maxUnavailable 설정 불가
  - spec.podManagementPolicy가 Parallel이어도 병렬 업데이트 X

**Partition**

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: sample-ss-rollingupdate
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      partition: 3 # 3이상 인덱스 파드만 업데이트 (0, 1 인덱스 파드 업데이트 X)
  selector:
    matchLabels:
      app: sample-app # has to match .spec.template.metadata.labels
  serviceName: sample-ss-rollingupdate
  replicas: 5 # by default is 1
  template:
    metadata:
      labels:
        app: sample-app # has to match .spec.selector.matchLabels
    spec:
      containers:
        - name: nginx-container
          image: nginx:1.16
```

## 5.6.5. 영구 볼륨 데이터 저장 확인

> 메니페스트에 설정한 mount path에 free disk 마운트되어 있음
> ![alt text](image-15.png)

> 마운트된 볼륨에 할당된 디스크에 sample.html 생성
> ![alt text](image-10.png)

> 삭제 전 ip 확인
> ![alt text](image-11.png)

> 삭제 후 ip가 바꼈지만 재기동된 파드에 여전히 파일 존재
> ![alt text](image-13.png)

## 5.6.6. 스테이트풀셋 삭제와 영구 볼륨 삭제

스테이트풀셋을 삭제하고 영구 볼륨 클레임으로 확보한 영구 볼륨을 해제하지 않으면 계속 해당 디스크 공간이 확보된 상태로 유지된다. 이때 다시 스테이트풀셀을 생성하면 해당 디스크로 공간으로 영구 볼륨이 마운트된다. 당연히 데이터 역시 유지된다.
![alt text](image-16.png)

디스크가 확보된 상태로 방치할 경우 비용이 발생하므로 스테이트풀셋을 삭제하고 더 이상 쓰지 않는 영구 볼륨이라면 해제하도록 하자.

> 영구 볼륨 클레임 해제
> ![alt text](image-17.png)

> 영구 볼륨 삭제 확인
> ![alt text](image-18.png)

# 5.7. 잡
