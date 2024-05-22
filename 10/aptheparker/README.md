# 사용자 스토리지 클래스를 지정해 헬름 차트 MySQL 설치하기

1. Helm으로 MySQL을 설치.
   ![Pull MySQL Image](./images/pull-mysql-image.png)
   ![Install MySQL](./images/install-mysql.png)

2. my-values.yaml 파일을 생성하고 MySQL 설정을 추가.
   ![Create my-values.yaml](./images/create-my-values.png)
   ![primary persistence](./images/primary-persistence.png)
   ![secondary persistence](./images/secondary-persistence.png)

3. MySQL 설치.
   ![Install MySQL with my-values.yaml](./images/install-mysql-with-my-values.png)

4. pvc 삭제
   ![pvc delete](./images/pvc-delete.png)
