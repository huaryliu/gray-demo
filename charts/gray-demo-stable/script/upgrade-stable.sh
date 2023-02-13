#!/bin/sh

export APP_NAME=<CHARTNAME>
export APP_VERSION=1.0.0
export SUBSET=stable
export CUSTOM=""

# export HELM_CHART=helm-csp/$APP_NAME --version 0.1.0
export HELM_CHART=$APP_NAME
export RELEASE_NAME=$APP_NAME-$SUBSET
export ALREADY_INSTALLED=$(helm ls -qf $RELEASE_NAME)

export VALUES=" \
  --set global.grayscale.enabled=true \
  --set global.grayscale.subset=$SUBSET \
  --set appVersion=$APP_VERSION \
  $CUSTOM \
  $*"
#--set redis.clusterDomain=k8s-02.iec

if [ -z "$ALREADY_INSTALLED" ]; then
  echo "$RELEASE_NAME has not been installed yet. Trying to install instead of upgrade..."
  helm install $RELEASE_NAME $HELM_CHART $VALUES

else
  echo "Trying to upgrade $RELEASE_NAME..."
  helm upgrade $RELEASE_NAME $HELM_CHART $VALUES
fi
