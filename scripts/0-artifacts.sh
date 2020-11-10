#!/bin/bash
set -x

OCP_RELEASE_MAYOR="4.$(echo $OCP_RELEASE | awk -F . '{print $2}')"


mkdir -p ${MYPATH}/artifacts/bin

curl --compressed -J -L -o ${MYPATH}/artifacts/openshift-install-linux-${OCP_RELEASE}.tar.gz  https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_RELEASE}/openshift-install-linux-${OCP_RELEASE}.tar.gz
tar -C ${MYPATH}/artifacts/bin/ -xvf ${MYPATH}/artifacts/openshift-install-linux-${OCP_RELEASE}.tar.gz

        curl --compressed -J -L -o ${MYPATH}/artifacts/openshift-client-linux-${OCP_RELEASE}.tar.gz  https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${OCP_RELEASE}/openshift-client-linux-${OCP_RELEASE}.tar.gz
        tar -C ${MYPATH}/artifacts/bin/  -xvf  ${MYPATH}/artifacts/openshift-client-linux-${OCP_RELEASE}.tar.gz

        curl -L -o ${MYPATH}/artifacts/rhcos-${OCP_RELEASE}-x86_64-vmware.x86_64.ova https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${OCP_RELEASE_MAYOR}/latest/rhcos-vmware.x86_64.ova

        #curl -L -o ${MYPATH}/artifacts/rhcos-rootfs.img https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${OCP_RELEASE_MAYOR}/latest/rhcos-live-rootfs.x86_64.img


cp ${MYPATH}/artifacts/bin/oc /usr/local/bin/
cp ${MYPATH}/artifacts/bin/openshift-install /usr/local/bin/
