# 보안

## 파드 보안 정책: PodSecurityPolicy

- 보안 정책을 설정해서 클러스터에 제한을 둔다
  - 파드에 대한 제한사항 설정
  - 보안 컨텍스트들에 대한 기본값 설정
- 기본적으로 비활성화 되어있음
- 파드 보안정책 활성화: `$ gcloud beta container clusters update k8s --enabel-pod-security-policy --zone asia-northeast3-a`
- 화이트리스트 방식: 허용되는것들을 명시해 줘야함
  - 단순히 활성화만 된 상태에서는 파드 생성 불가능
  - 하나 이상의 파드 보안 정책들을 생성해야 함
  - GKE에서는 기본적으로 파드 보안정책을 활성화 할 때 몇개의 파드 보안 정책이 생성되므로 해당 default 파드 정책들에 부합하는 파드들은 처음부터 생성가능
- 여러개의 파드 보안정책이 있을 때 하나 이상의 정책과 맞는 파드들만 생성 가능
  - `Error from server (Forbidden): error when creating "sample-pod.yaml": pods "sample-pod" is forbidden: unabel to validate against any pod security policy: []`
- 예시
  ```
  # sample-podsecuritypolicy.yaml
  apiVersion: policy/v1beta1
  kind: PodSecurityPolicy
  metadata:
    name: sample-podsecuritypolicy
  spec:
    privileged: false
    runAsUser:
      rule: RunAsAny
    allowPrivilegeEscalation: true
    allowedCapabilities:
    - '*'
    allowedHostPaths:
    - pathPrefix: "/etc"
    fsGroup:
      rule: RunAsAny
    supplementalGroups:
      rule: RunAsAny
    seLinux:
      rule: RunAsAny
    volumes:
    - '*'
  ```
- 파드 보안 정책 생성: `$ kubectl apply -f sample-podsecuritypolicy.yaml`
- 클러스터롤에 파드 보안 정책 연결:
  ```
  kubectl create --save-config clusterrole psp-test-clusterrole \
  --verb=use \
  --resource=podsecuritypolicy \
  --resource-name=sample-podsecuritypolicy
  ```
- 서비스 어카운트에 클러스터롤 연결:
  ```
  kubectl create --save-config clusterrolebinding psp-test-clusterrolebinding \
  --clusterrole=psp-test-clusterrole \
  --serviceaccount=default:psp-test
  ```
- 이제 일반 파드는 생성 가능
- 위 yaml 파일의 정책과 맞지 않는 설정을 가진 파드는 생성 불가능
- 레플리카셋의 파드 보안 정책
  - 레플리카셋을 만들때는 레플리카셋이 파드를 생성하기 때문에 파드에 레플리카셋의 보안 정책이 적용된다
  - kube-system의 replicaset-controller 서비스 어카운트를 사용
  - 해당 어카운트에는 파드 보안 정책이 추가되어있지 않아 레플리카셋이 파드 생성이 불가능하다
  - 레플리카셋 매니페스트의 파드 템플릿에 serviceAccountName을 추가해서 해당 서비스 어카운트가 보안정책에 대한 권한을 가지고 있다면 해당 레플리카셋에 권한이 없더라도 해당 보안정책 안에서 파드를 생성할 수 있다
  - `$ kubectl get pods -o custom-columns-'NAME:.mtadata.name,SERVICEACCOUNT:.spec.serviceAccountName'`으로 파드들의 serviceAccountName을 확인 가능
- 파드 보안 정책 비활성화: `$ gcloud beta container clusters update k8s --no-enable-pod-security-policy --zone asia-northeast3-a`

## 네트워크 정책

- 파드간 통신에 대한 규칙
- 네트워크 정책으로 특정 파드들 사이만 통신 가능하도록 제한
- 네트워크 정책 사용하기
  - 온프레미스 환경: 네트워크 정책을 지원하는 CNI 플러그인이 있어야 함 (ex: Calico)
  - GKE의 경우 명시적으로 활성화 가능
- 네임스페이스 별로 각각 생성해야 함

### 네트워크 정책 생성

```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: sample-networkpolicy
  namespace: default # 보안 정책을 생성할 네임스페이스 지정
spec:
  podSelector:
    # 설정할 대상 파드를 여기에 기입
    # 레이블 셀렉터이므로 복수의 파드를 대상으로 할 수 있음.
  policyTypes:
  - Ingress # 인그레이스 룰을 생성하는 경우 명시
  - Egress # 이그레스 룰을 생성할 경우 명시
  ingress:
  - from:
      # 인그레스 룰을 여기에 기입(이그레스 룰과 형식은 동일）
    ports:
      # 이 인그레스 룰로 허가할 수신 포트 번호와 프로토콜 기입
  egress:
  - to:
      # 이그레스 룰을 여기에 기입(인그레스 룰과 형식은 동일）
    ports:
      # 이 이그레스 룰로 허가할 송신 포트 번호와 프로토콜 기입
```

- ingress: 들어오는 방향의 통신 규칙 지정
- egress: 송신 방향의 통신 규칙 지정
- | podSelector             | namespaceSelector                                   | ipBlock                    |
  | ----------------------- | --------------------------------------------------- | -------------------------- |
  | 특정 파드와의 통신 허가 | 특정 네임스페이스 안의 모든 파드들에 대한 통신 허가 | 특정 IP 주소와의 통신 허가 |
- 모든 트래픽 차단:

```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-networkpolicy
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

- 모든 트래픽 허용:

```
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-all-networkpolicy
spec:
  podSelector: {}
  egress:
  - {}
  ingress:
  - {}
  policyTypes:
  - Ingress
  - Egress
```

- 클라우드 에서는 수신 방향은 전체를 차단하고 발신은 전체를 허용해주는것이 일반적

- 네트워크 정책 생성: `$ kubectl apply -n <namspace> -f <네트워크 정책 yaml 파일>`
- 네트워크 정책 조회: `$ kubectl get networkpolicy`
- 네트워크 정책 삭제: `$ kubectl delete networkpolicy <policy-name>`

- 네트워크 규칙 예시
  - 특정 파드에서 오는 통신만 허용
  ```
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
  	name: sample-podselector-ingress-networkpolicy
  spec:
  	podSelector:
  		matchLabels:
  			app: np2
  	policyTypes:
  	- Ingress
  	ingress:
  	- from:
  		- podSelector:
  				matchLabels:
  					app: np1
  		ports:
  		- protocol: TCP
  			port: 80
  ```
  - 특정 네임스페이스에서 오는 통신만 허용
  ```
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
  	name: sample-namespaceselector-ingress-networkpolicy
  	namespace: nptest
  spec:
  	podSelector:
  		matchLabels:
  			app: np3
  	policyTypes:
  	- Ingress
  	ingress:
  	- from:
  		- namespaceSelector:
  				matchLabels:
  					ns: default
  		ports:
  		- protocol: TCP
  			port: 80
  ```
  - 특정 IP와의 통신만 허용
  ```
  apiVersion: networking.k8s.io/v1
  kind: NetworkPolicy
  metadata:
  	name: sample-ipblock-ingress-networkpolicy
  	namespace: nptest
  spec:
  	podSelector:
  		matchLabels:
  			app: np4
  	policyTypes:
  	- Ingress
  	ingress:
  	- from:
  		- ipBlock:
  				cidr: 10.24.0.10/32 # 허용할 파드의 IP 주소
  		ports:
  		- protocol: TCP
  			port: 80
  ```
- https://github.com/ahmetb/kubernetes-network-policy-recipes
- 한 파드를 대상으로 한 networkPolicy가 여러개일 경우 조건들이 합집합으로 적용됨

## 인증/인가 & 어드미션 컨트롤

- 어드미션 컨트롤(admission control): 클러스터에 들어오는 API 요청을 중간에서 접수해서 해당 요청을 허용할지 판단하거나 요청을 수정할 수 있다
- 사용자가 요청을 보낼 때
  - 인증: 토큰, 비밀번호 등으로 사용자가 정상 사용자인지 확인
  - 인가: 사용자가 해당 요청에 대한 권한이 있는지 확인
  - 어드미션 컨트롤: 해당 요청을 처리함
- 어드미션 컨트롤의 두가지 종류
  - Mutating Admission Controller: 요청을 쿠버네티스 클러스터 관리자가 변형 가능
    - 사용하는 리소스에 제한 걸기
    - 생성하는 객체의 설정 수정 등
  - Validating Admission Controller: 해당 요청을 허가할지 판단함
    - 파드 정책에 어긋나지는 않는가?

## 파드 프리셋

## 시크릿 리소스 암호화
