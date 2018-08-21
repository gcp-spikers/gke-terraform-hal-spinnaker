#!/bin/bash
PID=$(ps -ef | grep '[k]ubectl' | tr -s ' ' '|' | cut -f3 -d '|') 
if [[ ! -z "$PID" ]]; then
  kill $PID
fi
kubectl -n=spinnaker port-forward $(kubectl -n=spinnaker get pods -l=load-balancer-spin-deck=true -o=jsonpath='{.items[0].metadata.name}') 9000 > /dev/null &
kubectl -n=spinnaker port-forward $(kubectl -n=spinnaker get pods -l=load-balancer-spin-gate=true -o=jsonpath='{.items[0].metadata.name}') 8084 > /dev/null &
