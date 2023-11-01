#!/bin/bash

VALUES_YAML="../../config/k8s/otomi/values.yaml" # add a values yaml to your repo
OTOMI_HELM_REPO=$(helm repo list | grep otomi )
if [ -z $OTOMI_HELM_REPO ]; then
    echo "Otomi Helm repo not found, adding"
    helm repo add otomi https://otomi.io/otomi-core
    helm repo update
else
    echo "Otomi Helm repo found, checking for release"
fi

OTOMI_RELEASE_EMPTY=$(helm list -n otomi | grep otomi | awk '{print $1}')
if [ -z $OTOMI_RELEASE_EMPTY ]; then
    echo "Otomi not found, installing"
else
    echo "Otomi already installed"
    helm uninstall otomi --no=hooks
    exit 0
fi

helm install -f $VALUES_YAML otomi otomi/otomi