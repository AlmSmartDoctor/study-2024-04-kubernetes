# 13.1. 서비스 어카운트

- UserAccount
  - GKE의 구글계정 또는 EKS의 IAM과 연결
  - 클러스터 수준의 존재로 네임스페이스의 영향 받지 않음
- ServiceAccount
  - 파드에서 실행되는 프로세스를 위해 할당
  - 네임스페이스와 연결된 리소스로 파드 기동시 반드시 한 개 할당

## 13.1.1. 서비스 어카운트 생성

```shell
kubectl create serviceaccount sample-serviceaccount
```

```shell
# 인증이 필요한 개인 저장소의 이미지를 가져오기
kubectl patch serviceaccount sample-serviceaccount \
-p '{"imagePullSecrets": [{"name": "myregistrykey"}]}'
```

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sample-serviceaccount
  namespace: default
imagePullSecrets:
  - name: myregistrykey
```

## 13.1.2. 서비스 어카운트와 토큰

```shell
# 서비스 어카운트 정보 확인
kubectl get serviceaccounts sample-serviceaccount -o yaml
```

**OUTPUT**

```yaml
apiVersion: v1
---
secrets:
  - name: sample-serviceaccount-token-b76nf
```

- 위 시크릿은 쿠버네티스가 자동으로 생성해줌
- 토큰을 변경하고 싶을 때는 해당 시크릿을 삭제하면 자동으로 재생성됨

**파드에 할당된 서비스 어카운트의 권한이 곧 파드의 권한이 된다**

```shell
# 서비스 어카운트에 연결된 시크릿
kubectl get secrets sample-serviceaccount-token-csggg -o yaml
```

파드의 서비스 어카운트를 명시적으로 지정

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: sample-pod
spec:
  serviceAccountName: sample-serviceaccount
  containers:
  ...
```

```shell
kubectal get pods sample-serviceaccount -o yaml
```

```yaml
apiVersion: v1
...
spec:
  - image: nginx:1.16
  ...
  volumeMounts:
    - mountPath: /var/run/secrets/kubernetes.io/serviceaccount
      name: sample-servceaccount-token-b76nf
      readOnly: true
  ...
  volumes:
    - name: sample-servceaccount-token-b76nf
      secret:
        defaultMode: 420
        secretName: sample-serviceaccount-token-b76nf
  ...
```

- 마운트된 볼륨에는 토큰과 인증서 등이 저장됨
- 파드는 이를 사용해 지정된 서비스 어칸운트 권한으로 어플리케이션 실행

```shell
# API 서버 인증에 사용되는 토큰과 인증서 확인
kubectl exec -it sample-serviceaccount-pod -- ls /var/run/secrets/kubernetes.io/serviceaccount
```

## 13.1.3. 토큰 자동 마운트

- 토큰이 자동으로 마운트되는 것을 비활성화 가능
- automountServiceAccountToken을 false로 설정

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ~
automountServiceAccountToken: false
```

- 위 서비스 어카운트로 기동되는 파드는 기본값으로 토큰을 볼륨에 마운트 하지 않지만 spec.automountServiceAccountToken을 true로 설정하여 마운트 가능

```yaml
apiVersion: v1
kind: Pod
metadata:
---
spec:
  automountServiceAccountToken: true
```

**파드 설정이 우선**

## 13.1.4. 클라이언트 라이브러리와 인증

- 서비스 어카운트 토큰 사용 (In-Cluster Config)
- kubeconfig 인증 정보를 지정

## 13.1.5. 도커 레지스트리 인증 정보 자동 설정

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sample-serviceaccount-pullsecret
imagePullSecrets:
  - name: sample-registry-auth
```

```shell
kubectl get pods sample-pod -o yaml
...
spec:
  ...
  imagePullSecrets:
  - name: sample-registry-auth
  ...
```

- 파드 기동시 spec.imagePullSecrets를 지정하지 않아도 자동으로 포함됨
- spec.imagePullSecrets는 복수 지정도 가능하여 여러 인증 정보 설정 가능

# 13.2. RBAC

- 롤: 어떤 조작을 허용하는지 결정
- 서비스어카운트 등의 사용자에게 롤 바인딩하여 권한 부여
- AggregationRule: 여러 롤을 묶은 롤 생성 가능
- 네임스페이스 수준: 롤, 롤바인딩
- 클러스터 수준: 클러스터 롤, 클러스터 롤바인딩

## 13.2.1. 롤과 클러스터롤

- 롤에 지정할 수 있는 실행 가능 조작
  - \*: 모두 처리
  - create
  - delete
  - get
  - list
  - patch
  - update
  - watch

### 롤 생성

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: sample-role
rules:
  - apiGroups:
      - apps
      - extensions
      resources:
        - replicasets
        - deployments
        - deplooyments/scale
      verbs:
        - "*"
```

### 클러스터롤 생성

- nonResourceURLs 지정 가능
- namespace 지정 불가

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: sample-clusterrole
rules:
  - apiGroups
    - apps
    - extensions
    resources:
      - replicasets
      - deployments
    verbs:
      - get
      - list
      - watch
- nonResourceURLs:
  - /healthz
  - /healthz/*
  - /version
  verbs:
    - get
```

### Aggregation

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: sample-aggregated-cluterrole
aggregationsRule:
  clusterRoleSelectors:
    - matchLabels:
      app: sample-rbac
rules:
  - apiGroups: []
    resources: ["pods"]
    verbs: ["get"]
```

- matchLabel에 지정된 label을 가진 클러스터롤 그룹화됨

### 쿠버네티스 프리셋 클러스터롤

- system:~
  - ex) system:controller:attachdetach-controller

## 13.2..2 롤바인딩과 클러스터롤바인딩

### 롤바인딩 생성

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: sample-rolebinding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: sample-role
subjects:
  - kind: ServiceAccount
    name: sample-serviceaccount
```

### 클러스터롤 바인딩 생성

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: sample-clusterrolebinding
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: sample-clusterrole
subjects:
  - kind: ServiceAccount
    name: sample-serviceaccount
```

# 13.3. 보안 컨텍스트

- privileged: 특수 권한 컨테이너 실행
- capabilities: capabilities 추가 삭제
- allowPrivilegeEscalation: 컨테이너 실행 시 상위 프로세스보다 많은 권한을 부여할 지 여부
- readOnlyRootFilesystem
- runAsUser
- runAsGroup
- runAsNonRoot
- seLinuxOptions

## 13.3.1. 특수 권한 컨테이너 생성

컨테이너 내부에서 기동하는 프로세스와 리눅스 capabilities가 호스트와 동등한 권한을 가지게 됨

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ~
spec:
  containers:
    - name: ~
      image: ~
      securityContext:
        privileged: true
```

## 13.3.2. Capabilities 부여

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: sample-capabilities
spec:
  containers:
    - name: tools-container
      image: ~
      securityContext:
        capabilities:
          add: ["SYS_ADMIN"] # 부여
          drop: ["AUDIT_WRITE"] # 제거
```

## 13.3.3. root 파일 시스템의 읽기 전용 설정

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: sample-rootfile-readonly
spec:
  containers:
    - name: ~
    ...
    securityContext:
      readOnlyRootFilesystem: true
```

# 13.4. 파드 보안 컨텍스트

- runAsUser
- runAsGroup
- runAsNonRoot
- supplementalGroups
- fsGroup
- sysctls
- seLinuxOptions

## 13.4.1. 실행 사용자 지정

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ~
spec:
  securityContext:
    runAsUser: 65534
    runAsGroup: 65534
    supplementalGroups:
      - 1001
      - 1002
```

## 13.4.2. 루트 사용자로 실행 제한

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: ~
spec:
  securityContext:
    runAsNonRoot: true
```

## 13.4.3. 파일 시스템 그룹 지정

- 일번적으로 마운트한 볼륨의 소유자와 그룸은 root
- 실행 사용자에게 마운트한 볼륨에 권한 부여

```yaml
spec:
  securityContext:
    fsGroup: 1001
```

## 13.4.4. sysctl을 사용한 커널 파라미터 설정

```yaml
spec:
  securityContext:
    sysctls:
      - name: net.core.somaxconn
        value: "12345"
```

- safe : 호스트의 커널과 적절하게 분리되어 있으며 다른 파드에 영향이 없고 파드가 예상치 못한 리소스를 소비하지 않음
- unsafe한 커널 파라미터를 변경할 때는 초기화 컨테이너 사용
  - 변경할 커널 파람에 따라 특수 권한 컨테이너 설정 필요

```yaml
spec:
  iniContainers:
    - name: initialize-sysctl
      image: busybox:1.27
      command:
        - /bin/sh
        - -c
        - |
          sysctl -w net.core.somaxconn=12345
  securityContext:
    privileged: true
```
