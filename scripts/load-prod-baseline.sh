kubectl exec -it $(kubectl get po --no-headers -l cluster=helloworld-prod-baseline | cut -f1 -d' ')  bash < generate-info-log.sh
