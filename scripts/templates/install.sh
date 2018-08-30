#!/bin/bash

set -exo pipefail

APP_NAME=$1

SPINNAKER_API=http://localhost:8084/
CANARY_CONFIG_ID="753fbdeb-6c51-495f-98a6-17b3dcd6010f"

# Install the templates 
roer pipeline-template publish common-modules.yml
roer pipeline-template publish deployToTest.yml
roer pipeline-template publish deployToProd.yml
roer pipeline-template publish cleanupCanary.yml

sed "s/<APP_NAME>/$APP_NAME/" services.yml > /tmp/$APP_NAME-services.yml

kubectl apply -f /tmp/$APP_NAME-services.yml

roer app  create $APP_NAME app.yml

sed "s/<APP_NAME>/$APP_NAME/" deployToTest-config.yml > /tmp/$APP_NAME-deployToTest-config.yml
roer pipeline save  /tmp/$APP_NAME-deployToTest-config.yml
TEST_DEPLOY_PIPELINE_ID=$(roer pipeline get $APP_NAME  "Deploy to Dev" | jq '.id' | tr -d '"')

echo "TEST_DEPLOY_PIPELINE_ID: $TEST_DEPLOY_PIPELINE_ID"

sed "s/<APP_NAME>/$APP_NAME/" deployToProd-config.yml | \
  sed "s/<TEST_DEPLOY_PIPELINE_ID>/$TEST_DEPLOY_PIPELINE_ID/"  | \
  sed "s/<CANARY_CONFIG_ID>/$CANARY_CONFIG_ID/" > /tmp/$APP_NAME-deployToProd-config.yml
roer pipeline save  /tmp/$APP_NAME-deployToProd-config.yml
PROD_DEPLOY_PIPELINE_ID=$(roer pipeline get $APP_NAME  "Deploy to Prod" | jq '.id' | tr -d '"')

echo "PROD_DEPLOY_PIPELINE_ID: $PROD_DEPLOY_PIPELINE_ID"

sed "s/<APP_NAME>/$APP_NAME/" cleanupCanary-config.yml | \
  sed "s/<PROD_DEPLOY_PIPELINE_ID>/$PROD_DEPLOY_PIPELINE_ID/" > /tmp/$APP_NAME-cleanupCanary-config.yml
roer pipeline save  /tmp/$APP_NAME-cleanupCanary-config.yml
