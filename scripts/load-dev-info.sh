kubectl exec -it $(kubectl get po --no-headers -l cluster=helloworld-dev | cut -f1 -d' ')  bash < generate-info-log.sh 
