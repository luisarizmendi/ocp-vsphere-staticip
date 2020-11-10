#!/bin/bash
set -x

mkdir ${MYPATH}/install

cp ${MYPATH}/install-config.yaml ${MYPATH}/install/

openshift-install create manifests --dir=${MYPATH}/install
rm -f ${MYPATH}/install/openshift/99_openshift-cluster-api_master-machines-*.yaml ${MYPATH}/install/openshift/99_openshift-cluster-api_worker-machineset-*.yaml

openshift-install create ignition-configs --dir=${MYPATH}/install

yum install -y jq 
export GOVC_FOLDER="$( jq -r .infraID ${MYPATH}/install/metadata.json)"


