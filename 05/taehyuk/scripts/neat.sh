kubectl run busybox --image=busybox

kubectl krew install neat

kubectl get pod busybox -o yaml | kubectl neat > busybox.yaml

kubectl delete pod busybox