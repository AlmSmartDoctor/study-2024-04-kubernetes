# 1. nginx yaml with wrong version

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: errorNginx
spec:
  containers:
    - image: nginx:1.19.19
      name: nginx
```

# 2. run

![alt text](image.png)

# 3. describe

![](images/describe.png)

> now fix version to 1.19

# 4. Logs

![](images/log.png)

# 5. get events

![](images/getevent.png)
