#!/bin/bash
set -x
export OCP_RELEASE="4.6.1"

export HTTP_SERVER="jumphost01.srv.demo"

export http_proxy=http://proxy.srv.demo:8080
export https_proxy=http://proxy.srv.demo:8080
export no_proxy=".oc.pre.srv.demo,api.oc.pre.srv.demo,api-int.oc.pre.srv.demo,172.27.150.0/23,172.30.0.0/16,10.128.0.0/14"

export MYPATH=$(pwd)


export CLUSTER_DOMAIN="oc.pre.srv.demo"
export GOVC_URL='vcenter01.srv.demo'
export GOVC_USERNAME='openshift@vsphere.local'
export GOVC_PASSWORD='superpassword'
export GOVC_INSECURE=1

export GOVC_NETWORK='4_TEST-APLIC'
## if multiple networks you need to add the vswitch name with "/" at the end, if not let it empty
export VMWARE_SWITCH='vDS-DEVELOPMENT/'

export GOVC_DATASTORE='mydatastore'
export GOVC_DATACENTER='DC1'
export GOVC_RESOURCE_POOL="/${GOVC_DATACENTER}/host/<name>/Resources"

##This will be updated with clustername
export GOVC_FOLDER='openshift'


export OVA_name="rhcos_vmware.x86_64"
export OVA_library="rhcos-images"

export bootstrap_name="bootstrap"
export bootstrap_ip="172.27.150.202"

export master_name="master"
export master1_ip="172.27.150.203"
export master2_ip="172.27.150.205"
export master3_ip="172.27.150.206"

export worker_name="worker"
export worker1_ip="172.27.150.207"
export worker2_ip="172.27.150.208"
export worker3_ip="172.27.150.209"

export MASTER_CPU="4"
export MASTER_MEMORY="16384"

export WORKER_CPU="16"
export WORKER_MEMORY="65536"


export ocp_net_gw="172.27.150.1"
export ocp_net_mask="255.255.254.0"
export ocp_net_dns="172.16.0.2"




echo "STEP 0 - CREATE ARTIFACTS"
echo "########################################"
./scripts/0-artifacts.sh

echo "STEP 1 - CREATE IGNITION FILES"
echo "########################################"
./scripts/1-ignitions.sh


echo "STEP 2 - INSTALL HTTPD SERVER"
echo "########################################"
./scripts/2-httpd.sh

echo "STEP 3 - CONFIG VSPHERE"
echo "########################################"
./scripts/3-vsphere.sh





mkdir ~/.kube
yes | cp ${MYPATH}/install/auth/kubeconfig ~/.kube/config

openshift-install wait-for bootstrap-complete --dir=${MYPATH}/install

for i in $(/usr/local/bin/oc get csr -o name  --all-namespaces); do  /usr/local/bin/oc adm certificate approve $i ; /usr/local/bin/oc adm certificate approve $i ;done

openshift-install wait-for install-complete --dir=${MYPATH}/install
