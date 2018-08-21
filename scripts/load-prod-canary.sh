kubectl exec -it $(kubectl get po --no-headers -l cluster=helloworld-prod-canary | cut -f1 -d' ')  bash < generate-error-log.sh
