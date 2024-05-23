# Chapter 7. 컨피그 & 스토리지 API ( 7.5 영구 볼륨 클레임 ~ )

## 7.5 영구 볼륨 클레임

- 볼륨
  - 미리 준비된 볼륨을 직접 지정하여 사용
  - 볼륨 생성 및 삭제 x
- 영구 볼륨
  - 외부 영구 볼륨 제공 시스템과 연계하여 새로 생성 및 삭제
  - 매니페스트에서 영구 볼륨 리소스 생성
- 영구 볼륨 클레임
  - 영구 볼륨 리소스 할당 리소스

## 7.6 볼륨

볼륨 플러그인 종류

- **emptyDir**
- **hostPath**
- **downwardAPI**
- **projected**
- nfs
- iscsi
- cephfs

### 7.6.1 emptyDir

- 파드용 임시 디스크 영역으로 사용
- 파드가 종료되면 삭제
- 호스트의 임의 영역 마운트 x
  - 노드의 디스크 영역 할당

```yaml
# emptyDir 볼륨 마운트 (sample-empty.yaml)
apiVersion: v1
kind: Pod
metadata:
  name: sample-emptydir
spec:
  containers:
  - image: nginx: 1.16
    name: nginx-container
    volumeMounts:
    - mountPath: /cache
      name: cache-volume
  volumes:
  - name: cache-volume
    emptyDir: {}
```

```yaml
# 용량 제한 (sample-emptydir-limit.yaml)
apiVersion: v1
kind: Pod
metadata:
  name: sample-emptydir-limit
spec:
  containers:
  - image: nginx: 1.16
    name: nginx-container
    volumeMounts:
    - mountPath: /cache
      name: cache-volume
  volumes:
  - name: cache-volume
    emptyDir:
      sizeLimit: 128Mi
```

```yaml
# 메모리 영역 사용 & 용량 제한 (sample-emptydir-memory.yaml)
apiVersion: v1
kind: Pod
metadata:
  name: sample-emptydir-memory
spec:
  containers:
  - image: nginx: 1.16
    name: nginx-container
    volumeMounts:
    - mountPath: /cache
      name: cache-volume
  volumes:
  - name: cache-volume
    emptyDir:
      medium: Memory
      sizeLimit: 128Mi
```

### 7.6.2 hostPath

- 호스트의 임의 영역을 마운트
- type:
  - Directory
  - DirectoryOrCreate
  - File
  - Socket
  - BlockDevice
- 보안상 위험
  - hostPath를 사용할 수 없는 쿠버네티스 환경 존재

```yaml
# hostPath 볼륨 마운트 (sample-hostPath.yaml)
apiVersion: v1
kind: Pod
metadata:
  name: sample-hostpath
spec:
  containers:
  - image: nginx: 1.16
    name: nginx-container
    volumeMounts:
    - mountPath: /srv
      name: hostpath-sample
  volumes:
  - name: hostpath-sample
    hostPath:
      path: /etc
      type: DirectoryOrCreate
```

### 7.6.3 downwardAPI

- 파드 정보 등을 파일로 배치하기 위한 플러그인
- 환경 변수 fieldRef와 resourceFieldRef의 사용 방법과 동일

```yaml
# downwardAPI 볼륨 마운트 (sample-downward-api.yaml)
apiVersion: v1
kind: Pod
metadata:
  name: sample-downward-api
spec:
  containers:
  - image: nginx: 1.16
    name: nginx-container
    volumeMounts:
    - mountPath: /srv
      name: downward-api-volume
  volumes:
  - name: downward-api-volume
    downwardAPI:
      items:
      - path: "podname"
        fieldRef:
          fieldPath: metadata.name
      - path: "cpu-request"
        resourceFieldRef:
          containerName: nginx-container
          resource: requests.cpu
```

### 7.6.4 projected

- 시크릿/컨피그맵/downwardAPI/serviceAccountToken의 볼륨 마운트를 하나의 디렉터리에 통합

```yaml
# projected 볼륨 마운트 (sample-projected.yaml)
apiVersion: v1
kind: Pod
metadata:
  name: sample-projected
spec:
  containers:
  - image: nginx: 1.16
    name: nginx-container
    volumeMounts:
    - mountPath: /srv
      name: projected-volume
  volumes:
  - name: projected-volume
    projected:
      sources:
      - secret:
          name: sample-db-auth
          itmes:
          - key: username
            path: secret/username.txt
      - configMap:
          name: sample-configmap
          items:
          - key: nginx.conf
            path: configmap/nginx.conf
      - downwardAPI:
          items:
          - path: "podname"
            fieldRef:
              fieldPath: metadata.name
```

## 7.7 영구 볼륨(PV)

- 영속성 영역으로 확보된 볼륨
- 네트워크를 통해 디스크를 attach 하는 디스크 타입
- 개별 리소스로 생성한 후 사용
- 클러스터 리소스

### 영구 볼륨 종류

- GCE Persistent Disk
- AWS Elastic Block Store
- Azure File
- nfs
- iSCSI
- Ceph(RBD, CephFS)
- OpenStack Cinder
- GlusterFS
- Container Storage Interface(CSI)
  - 컨테이너 오케스트레이션 엔진과 스토리지 시스템을 연결하는 인터페이스
  - 다양한 프로바이더 사용 가능
    - ex) GCE Persistent Disk CSI Driver, AWS Elastic Block Store CSI Driver

### 영구 볼륨 생성

**레이블**

- 영구 볼륨 할당 시 원하는 볼륨 지정할 때 유용
- type/environment/speed

**용량**

- 준비된 영구 볼륨 중 가장 비슷한 용량의 볼륨이 할당
  - 작은 용량의 영구 볼륨을 준비해 두는 것이 좋음

**접근 모드**

- ReadWriteOnce(RWO)
  - 단일 노드에서 Read/Write 가능
- ReadOnlyMany(ROX)
  - 여러 노드에서 Read 가능
- ReadWriteMany(RWX)
  - 여러 노드에서 Read/Write 가능

영구 볼륨에 따라 지원하는 접근 모드가 다름

**Reclaim Policy**

영구 볼륨 클레임에서 사용된 후 그 영구 볼륨 클레임이 삭제되었을 때 영구 볼륨 자체의 동작 설정

- Delete
  - 영구 볼륨 자체가 삭제
  - GCP/AWS/OpenStack 등에서 확보되는 외부 볼륨의 동적 프로비저닝 때 주로 사용
- Retain
  - 영구 볼륨 자체를 삭제하지 않고 유지
  - 다른 영구 볼륨 클레임에 의해 다시 마운트 x
- Recycle
  - 영구 볼륨 데이터를 삭제하고 재사용 가능한 상태로 만듦
  - 다른 영구 볼륨 클레임에서 다시 마운트 가능
  - 쿠버네티스에서 더 이상 사용 x
  - 동적 프로비저닝 권장

**스토리지클래스**

> 동적 스토리지 프로비저닝을 관리하기 위한 설정 및 옵션을 제공하는 객체

```yaml
# 동적 영구 볼륨 프로비저닝 x 스토리지클래스 (sample-storageclass-manual.yaml)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: manual
provisioner: kubernetes.io/no-provisioner
```

## 7.8 영구 볼륨 클레임(PVC)

> 영구 볼륨을 요청하는 리소스

### 영구 볼륨 클레임 설정

- 레이블 셀렉터
- 용량
  - 영구 볼륨 클레임 용량이 영구 볼륨 용량보다 작으면 할당
  - 용량 지정이 안 되는 플러그인 존재
- 접근 모드
- 스토리지클래스

```yaml
# 영구 볼륨 클레임 (sample-pvc.yaml)
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: sample-pvc
spec:
  selector:
    matchLabels:
      type: gce-pv
    matchExpressions:
      - key: environment
        operator: In
        values:
          - stg
  resources:
    requests:
      storage: 3Gi
  accessModes:
    - ReadWriteOnce
  storageClassName: manual
```

### 파드에서 사용

```yaml
# 영구 볼륨 클레임을 사용하는 파드 (sample-pvc-pod.yaml)
apiVersion: v1
kind: Pod
metadata:
  name: sample-pvc-pod
spec:
  containers:
    - name: nginx-container
      image: nginx:1.16
      volumeMounts:
        - mountPath: '/usr/share/nginx/html'
          name: nginx-pvc
  volumes:
    - name: nginx-pvc
      persistentVolumeClaim:
        claimName: sample-pvc # 영구 볼륨 클레임 지정
```

### 동적 프로비저닝

- 영구 볼륨 클레임이 생성되는 타이밍에 동적으로 영구 볼륨을 생성하고 할당
- 사전에 영구 볼륨 생성할 필요 x
- 요청하는 용량의 영구 볼륨 할당
- 어떤 영구 볼륨을 생성할지 정의한 스토리지클래스를 지정해야함

```yaml
# 프로비저너를 사용한 스토리지클래스 (sample-storageclass.yaml)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: sample-storageclass
parameters:
  type: pd-ssd
provisioner: kubernetes.io/gce-pd
reclaimPolicy: Delete
```

```yaml
# 영구 볼륨 클레임에 스토리지클래스 지정 (sample-pvc-dynamic.yaml)
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: sample-pvc-dynamic
spec:
  storageClassName: sample-storageclass
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 3Gi
```

### 영구 볼륨 할당 타이밍 제어

```yaml
# 타이밍 제어 (sample-storageclass-wait.yaml)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: sample-storageclass-wait
parameters:
  type: pd-ssd
provisioner: kubernetes.io/gce-pd
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer # immediate(기본값)
```

### 영구 볼륨을 블록 장치로 사용

```yaml
# 블록 장치를 사용하는 영구 볼륨 (sample-pvc-block.yaml)
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: sample-pvc-block
spec:
  storageClassName: sample-storageclass
  volumeMode: Block # Filesystem(기본값)
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 3Gi
```

```yaml
# 블록 장치 마운트 (sample-pvc-block-pod.yaml)
apiVersion: v1
kind: Pod
metadata:
  name: sample-pvc-block-pod
spec:
  containers:
    - name: nginx-container
      image: nginx:1.16
      volumeDevices: # volumeMounts 대신 volumeDevices
        - devicePath: /dev/sample-block
          name: nginx-pvc
  volumes:
    - name: nginx-pvc
      persistentVolumeClaim:
        claimName: sample-pvc-block
```

### 볼륨 확장

- 동적 프로비저닝을 사용하고 크기 조정이 지원되는 볼륨 플러그인을 사용하는 경우 볼륨 확장 가능
- 스토리지클래스에 allowVolumeExpantion: true를 설정하고 지정
- 확장은 가능하지만 축소는 불가능

### 영구 볼륨 스냅샷과 클론

- VolumeSnapshot: 요청 (PVC)
- VolumeSnapshotClass: 사양 (StorageClass)
- VolumeSnapshotContent: 실체 (PV)

---

- CSI 플러그인 사용이 전제됨
- CSI 드라이버가 스냅샷 기능을 구현하고 있어야 함

### 스테이트풀셋에서 영구 볼륨 클레임(volumeClaimTemplate)

```yaml
# 영구 볼륨 클레임 템플릿을 사용한 스테이트풀셋 (sample-statefulset-with-pvc.yaml)
apiVersion: v1
kind: StatefulSet
metadata:
  name: sample-statefulset-with-pvc
spec:
  serviceName: statefulset-with-pvc
  replicas: 2
  selector:
    matchLabels:
      app: sample-pvc
  template:
    metadata:
      labels:
        app: sample-pvc
    spec:
      containers:
        - name: sample-pvc
          image: nginc:1.16
          volumeMounts:
            - name: pvc-template-volume
              mountPath: /tmp
  volumeClaimTemplates:
    - metadata:
        name: pvc-template-volume
      spec:
        accessModes:
          - ReadWriteOnce
        resources:
          requests:
            storage: 10Gi
        storageClassName: sample-storageclass
```

## 7.9 volumeMounts에서 사용 가능한 옵션

### 읽기 전용 마운트

```yaml
# ReadOnly (sample-readonly-volumemount.yaml)
apiVersion: v1
kind: Pod
metadata:
  name: sample-readonly-volumemount
spec:
  containers:
    - image: nginx:1.16
      name: nginx-container
      volumeMounts:
        - mountPath: /srv
          name: hostpath-sample
          readOnly: true # readOnly
  volumes:
    - name: hostpath-sample
      hostPath:
        path: /etc
        type: DirectoryOrCreate
```

### subPath

```yaml
# subPath (sample-subpath.yaml)
apiVersion: v1
kind: Pod
metadata:
  name: sample-subpath
spec:
  containers:
    - name: container-a
      image: alpine:3.7
      command: ['sh', '-c', 'touch /data/a.txt; sleep 86400']
      volumeMounts:
        - mountPath: /data
          name: main-volume
    - name: container-b
      image: alpine:3.7
      command: ['sh', '-c', 'touch /data/b.txt; sleep 86400']
      volumeMounts:
        - mountPath: /data
          name: main-volume
          subPath: path1
    - name: container-c
      image: alpine:3.7
      command: ['sh', '-c', 'touch /data/c.txt; sleep 86400']
      volumeMounts:
        - mountPath: /data
          name: main-volume
          subPath: path2
  volumes:
    - name: main-volume
      emptyDir: {}
```

/data/a.txt

/data/path1/b.txt

/data/path2/c.txt

- 각 컨테이너가 하나의 볼륨을 사용하면서도 영향을 주지 않도록 할 수 있음
- /path1/morepath 처럼 2계층 이상으로 지정 가능
