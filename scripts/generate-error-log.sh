set -e
PrevResult=""
while true; do
  Result=$(curl -s http://localhost:8080/err)
  if [[ "$Result" == "$PrevResult" ]]; then
    echo -n "."
  else
    echo "`hostname`: [$Result]"
    PrevResult="$Result"
  fi
  sleep 1
done
