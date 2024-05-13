kubectl run busybox --image=busybox:1.28 -n game-2048 --restart=Never -- sleep 1d

kubectl exec -it busybox -n game-2048 -- sh 