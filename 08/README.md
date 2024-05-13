<h2> 그 외 서비스 기능 </h2>

<h3>세션 어피니티</h3>

- 사용자 세션이 활성 상태일 때, 클라이언트의 네트워크 트래픽을 동일한 파드로 유도하는 기능이다. 사용자의 세션 상태가 파드에 로컬로 저장되는 상태 유지 애플리케이션에 필수적이다.
- 상태 관리가 단순해지고 성능이 향상된다. 별다른 인증이나 동기화가 필요 없기 때문이다.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  type: ClusterIP
  selector:
    app: my-app
  ports:
    - port: 80
      targetPort: 8080
  sessionAffinity: ClientIP
  sessionAffinityConfig:
  clientIP:
    timeoutSeconds: 1800 # 세션 길이만큼
```

<h3>외부 트래픽 정책</h3>

- 클라이언트 IP를 보존해야 할 때 사용한다. Cluster 말고 Local로 설정하면 서비스가 클라이언트의 IP 주소를 보존할 수 있어, 클라이언트 위치 추적, 로깅, 감사 등에 유용하다.
- 트래픽이 불필요한 노드를 거치지 않아도 되므로 NAT를 피하고 지연 시간을 줄일 수 있어 성능이 향상된다.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-loadbalancer
spec:
  type: LoadBalancer
  selector:
    app: my-app
  ports:
    - port: 80
      targetPort: 8080
  externalTrafficPolicy: Local
```

<h2> 헤드리스 서비스 </h2>

- 특정 애플리케이션들이 파드 간에 직접적이고 안정적인 통신을 할 수 있도록 지원하는 서비스로, 상태를 가진(stateful) 애플리케이션을 쿠버네티스에 배포할 때 특히 유용하다.
- 일반적인 서비스와 달리, 헤드리스 서비스는 고정된 IP 주소를 갖지 않는다. 대신, 서비스를 요청하는 쪽이 서비스를 제공하는 파드의 IP 주소들을 DNS 조회를 통해 직접 얻게 된다.
- 로드 밸런싱이나 단일 서비스 IP 없이 파드들에게 직접 연결할 수 있다. 이게 아니었다면 모든 통신이 proxy로 일어났을 것이다.

`(Ex)` MySQL 데이터베이스 클러스터를 쿠버네티스 클러스터 내에서 배포하는 경우, 각 MySQL 인스턴스는 고유한 식별자와 직접적인 네트워크 연결이 필요하다. 이러한 설정은 각 인스턴스가 마스터 또는 복제본으로서의 역할을 수행하며 데이터 일관성을 유지할 수 있게 한다. 헤드리스 서비스를 사용하면, 각 파드를 직접 관리하고 필요에 따라 특정 데이터베이스 서버에 직접 연결할 수 있다.

```yaml
# headless service
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  clusterIP: None  # 꼭 작성
  ports:
    - port: 3306
      name: mysql
  selector:
    app: mysql
```
```yaml
# stateful set
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql
  replicas: 3
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:5.7
        ports:
        - containerPort: 3306
        env:
        - name: MYSQL_ROOT_PASSWORD
          value: "yourpassword"
        command:
          - "bash"
          - "-c"
          - |
            # Set MySQL to listen on all addresses
            echo "Setting MySQL to listen on all IPs."
            sed -i 's/bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/' /etc/mysql/my.cnf
            # Run different commands based on the hostname
            if [ "$HOSTNAME" = "mysql-0" ]; then
              echo "Starting MySQL as Master"
              docker-entrypoint.sh mysqld
            else
              echo "Starting MySQL as Replica"
              docker-entrypoint.sh mysqld
            fi
        volumeMounts:
        - name: mysql-data
          mountPath: /var/lib/mysql
  volumeClaimTemplates:
  - metadata:
      name: mysql-data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: "standard"
      resources:
        requests:
          storage: 10Gi
```

<h2> ExternalName 서비스 </h2>

- 클러스터 내에서 사용하는 서비스 이름을 통해 외부의 DNS 이름으로 매핑하고 싶을 때 유용하다.
- 외부 서비스의 URL이나 IP가 바뀌어도 ExternalName 서비스 설정만 갱신하면 된다. 따라서 다수의 애플리케이션이나 서비스에서 해당 외부 서비스를 참조할 때, 각각의 설정을 일일이 수정할 필요가 없어 관리가 훨씬 용이해진다.

```yaml
  # external name service
  apiVersion: v1
  kind: Service
  metadata:
    name: my-external-db
  spec:
    type: ExternalName
    externalName: example.mysql.whichimade
```
```yaml
  # pod
  apiVersion: v1
  kind: Pod
  metadata:
    name: my-app
  spec:
    containers:
    - name: my-app-container
      image: my-app-image
      env:
        - name: DATABASE_HOST
          value: "my-external-db"
        - name: DATABASE_PORT
          value: "3306"
```

<h2> None-Selector 서비스 </h2>

- 특정 레이블에 의존하지 않고 수동으로 엔드포인트를 관리하며 트래픽을 라우팅하는 방법을 제공한다.
- 수동으로 엔드포인트를 구성함으로써 특정 IP 주소로 트래픽을 정확히 라우팅할 수 있어, 표준 배포의 일부가 아닌 특정 파드나 클러스터 외부의 리소스로 트래픽을 직접 지정할 때 유용하다.
- 쿠버네티스 클러스터에 통합되지 않은 기존 시스템이나 외부 시스템과의 연동을 용이하게 하기에, 쿠버네티스로 점차 전환되는 레거시 시스템을 위한 가교 솔루션으로 사용될 수 있다.

```yaml
  # no selector service
  apiVersion: v1
  kind: Service
  metadata:
    name: none-selector-service
  spec:
    ports:
      - protocol: TCP
        port: 80
        targetPort: 9376
```
```yaml
  # endpoints
  apiVersion: v1
  kind: Endpoints
  metadata:
    name: none-selector-service
  subsets:
    - addresses:
        - ip: 192.168.1.1  # 수동으로 지정된 IP 주소
      ports:
        - port: 9376
```

<h2> 인그레스 </h2>

- 클러스터 외부에서 클러스터 내 서비스로 HTTP 및 HTTPS 라우팅을 제공하는 API 리소스다.
- 단일 IP 주소 아래에서 여러 서비스를 노출할 수 있다.
- SSL/TLS 종료를 중앙에서 관리하여 인증서 관리를 간소화할 수 있다.
- URL 경로, 호스트 이름 또는 기타 기준에 따라 라우팅 규칙을 사용하여 트래픽을 다양한 백엔드 서비스로 전달할 수 있다.
- 로드 밸런싱 로직을 중앙에서 관리함으로써 여러 로드 밸런서가 필요 없어진다.

```yaml
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: example-ingress
    annotations:
      nginx.ingress.kubernetes.io/rewrite-target: /
  spec:
    rules:
    - host: www.example.com
      http:
        paths:
        - path: /service1
          pathType: Prefix
          backend:
            service:
              name: service1
              port:
                number: 80
    - host: www.example.com
      http:
        paths:
        - path: /service2
          pathType: Prefix
          backend:
            service:
              name: service2
              port:
                number: 80
```
<h4>L4와 L7 로드 밸런서의 차이점</h4>

`L4`
전송 계층에서 작동, IP 주소와 포트 번호를 기반으로 라우팅 결정
TCP, UDP 등 모든 유형의 트래픽을 처리할 수 있다.
ex) 쿠버네티스에서 type: LoadBalancer로 설정된 서비스.

`L7`
응용 프로그램 계층에서 작동, 요청의 내용(예: URL 경로, 호스트 이름, 헤더)을 기반으로 라우팅 결정.
HTTP/HTTPS 트래픽 전용으로 설계되었다.
ex) Nginx나 HAProxy와 같은 인그레스 컨트롤러

<h4>클라우드 서비스와 Nginx 인그레스의 차이점</h4>

`클라우드 인그레스 컨트롤러`
- -> 트래픽 진입점: 클라우드 인그레스를 사용할 때 트래픽은 먼저 클라우드 제공 업체의 로드 밸런서에 도달합니다. 이 로드 밸런서는 인그레스 리소스 생성 시 자동으로 구성 및 관리한다.

- 로드 밸런서 -> 노드: 클라우드 제공 업체의 로드 밸런서는 트래픽을 파드가 실행 중인 노드로 직접 전달한다. 어떤 노드로 트래픽을 보낼지는 로드 밸런서가 건강 검사 및 정책에 따라 결정한다.

- 노드 -> 파드: 트래픽이 노드에 도달하면, 내부의 kube-proxy 규칙과 서비스 정의에 따라 적절한 파드로 라우팅 된다. 이 단계는 목표 파드가 처음 선택된 노드에 없는 경우 클러스터 내에서 추가적인 홉이 발생할 수 있다.
 
- 로드 밸런싱, SSL 종료 및 라우팅 규칙이 자동으로 관리되고, WAF, 자동 스케일링, 분석과 같은 다른 클라우드 서비스와의 통합이 용이하다.

- 로드 밸런서의 동작에 대한 사용자의 제어가 특정 클라우드 제공 업체의 기능과 제한에 구속된다.

`Nginx 인그레스 컨트롤러`
- -> 트래픽 진입점: Nginx 인그레스의 경우, 트래픽은 로드 밸런서를 통해 들어오지만, 이는 AWS ELB와 같이 단순한 트래픽 전달 설정의 클라우드 로드 밸런서일 수 있으며, 노드포트 서비스를 통해 Nginx 인그레스 컨트롤러를 직접 노출시킬 수도 있다.

- Nginx 인그레스 컨트롤러 처리: Nginx 인그레스 컨트롤러는 클러스터 내의 파드로 실행되며, Nginx 서버가 인그레스 규칙에 따라 라우팅 결정을 한다.

- 직접 파드 라우팅: Nginx 인그레스 컨트롤러는 라우팅 규칙에 따라 트래픽을 대상 파드로 전달한다. 클라우드 인그레스와 달리, 트래픽 처리, SSL/TLS 종료 및 라우팅 로직이 클러스터 내에서 완전히 관리된다.

- 라우팅 규칙, SSL 설정 및 로드 밸런싱 알고리즘에 대한 제어가 가능하고, 클라우드 뿐만 아니라 온-프레미스 환경에서도 설치가 가능하다.

- 그렇지만 Nginx 인그레스 컨트롤러 및 관련 구성을 수동으로 설정해야 하고, 사용자가 업데이트 및 보안 패치 및 스케일링을 관리해야 합니다.

<h4>인그레스 리소스 생성</h4>
- 원하는 서비스와 파드들을 생성하고 나서 아래 리소스를 만들면 된다. 그러면 path에 따라 -> service -> pod으로 전송된다.

```yaml
  apiVersion: networking.k8s.io/v1
  kind: Ingress
  metadata:
    name: complex-ingress
    annotations:
      nginx.ingress.kubernetes.io/rewrite-target: /
  spec:
    rules:
    - host: app1.example.com
      http:
        paths:
        - path: /backend1
          pathType: Prefix
          backend:
            service:
              name: backend1
              port:
                number: 80
    - host: app1.example.com
      http:
        paths:
        - path: /backend2
          pathType: Prefix
          backend:
            service:
              name: backend2
              port:
                number: 80
```