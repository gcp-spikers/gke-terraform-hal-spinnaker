kubectl exec -it $(kubectl get po --no-headers -l cluster=helloworld-dev | cut -f1 -d' ' | tail -1)  bash < generate-error-log.sh
