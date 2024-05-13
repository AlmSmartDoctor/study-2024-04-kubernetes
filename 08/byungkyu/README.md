# 1. create ClusterIP service

![](images/2024-05-13-22-50-19.png)

# 2. wget from busybox

![](images/![](images/2024-05-13-23-42-25.png)failed.png)

![](images/2024-05-14-00-11-46.png)

# 3. service discovery

![](images/2024-05-14-00-16-58.png)

![](images/2024-05-14-00-17-15.png)

New pod(...-sv8px) is discovered

# 4. Load Balancing

![](images/2024-05-14-00-21-39.png)

Pod sv8px and hp7tb

![](images/2024-05-14-00-21-13.png)

Traffic distributed with rate 1:2

# 5. Connect between different namespaces

![](images/2024-05-14-00-32-21.png)

![](images/2024-05-14-00-37-12.png)

![](images/2024-05-14-00-37-33.png)

# 6. Connect from outside of cluster

![](images/2024-05-14-00-45-25.png)

![](images/2024-05-14-00-45-51.png)

curl works well

# 7. Configuring Load Balancing

kube-proxy doesn't exist?