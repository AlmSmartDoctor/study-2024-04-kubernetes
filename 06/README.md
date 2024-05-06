# 매니페스트 범용화, 오픈 소스 소프트웨어

### 1. 헬름

> 쿠버네티스 패키지 관리자 (Node.js의 npm과 Python의 pip와 유사)
- 패키지 = 차트

### 1-1. 헬름 설정

- 기본적으로 ~/.kube/config에서 사용하지만, 필요에 따라 --kubeconfig나 --kube-context 등을 사용한다
  - helm help로 설정 확인 가능

### 1-2. 헬름 차트

- 각 차트는 [깃허브](https://github.com/helm/charts)에서 관리되고 있다
- 성숙도에 따라 stable, incubator로 나뉨
  - stable: 업데이트 가능, 데이터 영속성 가능, 보안, 적절한 기본값, 쿠버네티스 모범 사례 준수 등등

**-> 현재 표준 소스는 아티팩트허브 https://artifacthub.io**

### 1-3. 헬름 명령어

#### 1) 차트 저장소 - `helm repo`

1. `helm repo add {URL}`: 로컬에 차트 저장소 추가
2. `helm repo list`: 추가된 저장소 표시
3. `helm repo update`: 저장소 업데이트

#### 2) 차트 검색 - `helm search`

1. `helm search hub {chart}`: 아티팩트허브에서 차트 검색
2.  `helm search repo {chart}`: 추가된 저장소에서 차트 검색, 로컬 데이터 상에서 이루어지며 퍼블릭 네트워크 접속 필요 X

#### 3) 정보 - `helm show`

1. `helm show values {repo/chart}`:  설정 가능한 파라미터 표시
2.  `helm show readme {repo/chart}`: 리드미 표시

#### 4) 설치 - `helm install`

- `helm install {사용자 지정 릴리스 이름} {repo/chart}`: 설치
- `--set`: 파라미터 값 덮어쓰기
- `--version`: 버전 선택
- `--values {파일명}`: 파라미터 코드화

#### 5) 테스트 - `helm test {사용자 지정 릴리스 이름}`

#### 6) 매니페스트 생성 - `helm template`

- `helm install` 명령어에서 install을 template으로 바꾸기만 하면 됨
- install 하기 전 매니페스트 확인 가능

#### 7) 릴리스 나열 - `helm list`

#### 8) 릴리스 삭제 - `helm uninstall {사용자 지정 릴리스 이름}`

#### 9) 차트 생성 - `helm create {차트명}`

- https://helm.sh/docs/helm/helm_create/
- 차트에서 다른 차트를 사용할 수 있음 (ex. Wordpress 차트 -> Maria DB 차트 사용)

#### 10) 차트 패키지화 - `helm package`

- tgz 형식으로 패키지화

### 2. Kustomize

- 환경마다 매니페스트를 생성하거나 특정 필드를 덮어쓰는 툴
- kubectl kustomize로 사용 가능

- kustomize 설정은 kustomization.yaml을 사용
- `kubectl kustomize {폴더명}`, 폴더에 kustomization.yaml가 존재해야 함

### 2-1. 여러 매니페스트 결합

``` yaml
resources:
- sample-deployment.yaml
- sample-lb.yaml
```

### 2-2. 네임스페이스 덮어쓰기

``` yaml
namespace: sample-namespace
resources:
- sample-deployment.yaml
- sample-lb.yaml
```

### 2-3. Prefix, Suffix 부여

``` yaml
namePrefix: prefix-
nameSuffix: -suffix
resources:
- sample-deployment.yaml
- sample-lb.yaml
```

결과:
``` yaml
metadata:
  name: prefix-original-name-suffix
```

### 2-4. 공통 메타데이터(레이블/어노테이션) 부여

``` yaml
commonLabels:
  label1: label1-val
commonAnnotations:
  annotation1: annotation1-val
resources:
- sample-deployment.yaml
- sample-lb.yaml
```

결과:
``` yaml
metadata:
  annotations:
    annotation1: annotation1-val
  labels:
    label1: label1-val
```

### 2-5. 이미지 덮어쓰기

``` yaml
images:
- name: nginx
  newName: new-nginx
  newTag: v2.0
resources:
- sample-deployment.yaml
- sample-lb.yaml
```

- 이름이 일치하는 이미지는 모두 바뀌기 때문에 주의
- newName, newTag 둘 둥 하나만 지정해도 됨

### 2-6. 오버레이로 값 덮어쓰기

1. base 디렉토리를 지정, 해당 디렉토리 아래에 kustomization.yaml 파일 추가
2. 환경에 따라 디렉토리 만들고, patchesStrategicMerge 지정

``` yaml
# production/kustomization.yaml
bases:
- ../resources-sample
patchesStrategicMerge:
- ./patch-replicas.yaml
images:
- name: nginx
  newTag: prouction
```

**-> patch-replicas.yaml의 설정값에 따라 기존 매니페스트를 패치하고, 이미지 태그도 변경**

``` yaml
# production/patch-replicas.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sample-deployment
spec:
  replicas: 100
```

- 덮어쓰는 패치 매니페스트는 kind나 name으로 리소스를 판별하고, spec 아래에 덮어쓰기를 하는 항목만 기재하면 된다.

### 2-7. 컨피그맵과 시크릿 동적 생성

``` yaml
resources:
- sample-deployment.yaml
configMapGenerator: # secretGenerator
- name: generated-configmap
  literals:
  - KEY1=VAL1
  files:
  - ./sample.txt
```

-> 컨피그맵을 생성하고 자동으로 deployment 매니페스트에 넣어줌
