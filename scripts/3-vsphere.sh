#!/bin/bash
set -x
GOVC_BIN="https://github.com/vmware/govmomi/releases/download/v0.23.0/govc_linux_amd64.gz"

#OCP_RELEASE="4.6.1"
#export CLUSTER_DOMAIN="pre.cluster.gva.es"
IGNITION_PATH="${MYPATH}/install"

#export GOVC_URL='vsphere.server.local'
#export GOVC_USERNAME='admin@vsphere.local'
#export GOVC_PASSWORD='password'
#export GOVC_INSECURE=1
#export GOVC_NETWORK='413_DGTI-TEST-SERV-APLIC'
#export GOVC_DATASTORE='ds1a_PREDES_pre_lin_02'
#export GOVC_RESOURCE_POOL='CLPREDES/Resources'
#export GOVC_DATACENTER='CA90'
#export GOVC_FOLDER='ocp4'


#MASTER_CPU="4"
#MASTER_MEMORY="16384"

#WORKER_CPU="16"
#WORKER_MEMORY="65536"


######################################

curl -L $GOVC_BIN | gunzip > /usr/local/bin/govc
chmod +x /usr/local/bin/govc


## OVA 

govc folder.create /${GOVC_DATACENTER}/vm/${GOVC_FOLDER}

#OCP_RELEASE_MAYOR="4.$(echo $OCP_RELEASE | awk -F . '{print $2}')"
#OVA="https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${OCP_RELEASE_MAYOR}/${OCP_RELEASE}/rhcos-${OCP_RELEASE}-x86_64-vmware.ova"
#curl $OVA -o rhcos-${OCP_RELEASE}-x86_64-vmware.ova

yum install -y jq
govc import.spec ${MYPATH}/artifacts/rhcos-${OCP_RELEASE}-x86_64-vmware.x86_64.ova | jq > options.json

vmware_switch_noslash=$(echo ${VMWARE_SWITCH} | awk -F / '{print $1}')
if  [ -z "$vmware_switch_noslash" ]
then
	template_net=$GOVC_NETWORK
else
	template_net="${vmware_switch_noslash}\/${GOVC_NETWORK}"
fi


sed -i "s/\"Network\": \"\"/\"Network\": \"${template_net}\"/g" options.json


#govc import.ova -options options.json -name=${OVA_name} ${MYPATH}/artifacts/rhcos-${OCP_RELEASE}-x86_64-vmware.x86_64.ova
govc library.create ${OVA_library}
govc library.import ${OVA_library}/${OVA_name} ${MYPATH}/artifacts/rhcos-${OCP_RELEASE}-x86_64-vmware.x86_64.ova



#Bootstrap node


govc library.deploy --pool="${GOVC_RESOURCE_POOL}" -ds=${GOVC_DATASTORE} ${OVA_library}/${OVA_name} ${bootstrap_name}.${CLUSTER_DOMAIN} 
#govc vm.clone -vm rhcos-${OCP_RELEASE}-x86_64-vmware -annotation=BootstrapNode -c=${MASTER_CPU} -m=${MASTER_MEMORY} -net ${GOVC_NETWORK} -net.address 00:50:56:8c:a6:00 -on=false -folder=${GOVC_FOLDER} -datastore-cluster=${GOVC_DATASTORE} -pool=${GOVC_RESOURCE_POOL} ${bootstrap_name}.${CLUSTER_DOMAIN}

govc vm.change -c=${MASTER_CPU} -m=${MASTER_MEMORY} -vm=${bootstrap_name}.${CLUSTER_DOMAIN}

govc vm.network.change  -net ${VMWARE_SWITCH}${GOVC_NETWORK}  -vm=${bootstrap_name}.${CLUSTER_DOMAIN} ethernet-0

govc vm.disk.change -vm ${bootstrap_name}.${CLUSTER_DOMAIN} -size 120GB


bootstrap=$(cat ${IGNITION_PATH}/append-bootstrap.ign | base64 -w0)

govc vm.change -e="guestinfo.ignition.config.data=${bootstrap}" -vm=${bootstrap_name}.${CLUSTER_DOMAIN}
govc vm.change -e="guestinfo.ignition.config.data.encoding=base64" -vm=${bootstrap_name}.${CLUSTER_DOMAIN}
govc vm.change -e="disk.EnableUUID=TRUE" -vm=${bootstrap_name}.${CLUSTER_DOMAIN}

govc vm.change -e="guestinfo.afterburn.initrd.network-kargs=ip=${bootstrap_ip}::${ocp_net_gw}:${ocp_net_mask}:${bootstrap_name}.${CLUSTER_DOMAIN}:ens192:off nameserver=${ocp_net_dns}" -vm=${bootstrap_name}.${CLUSTER_DOMAIN}







#Master Nodes


govc library.deploy --pool="${GOVC_RESOURCE_POOL}" -ds=${GOVC_DATASTORE} ${OVA_library}/${OVA_name} ${master_name}00.${CLUSTER_DOMAIN}    
govc library.deploy --pool="${GOVC_RESOURCE_POOL}" -ds=${GOVC_DATASTORE} ${OVA_library}/${OVA_name} ${master_name}01.${CLUSTER_DOMAIN}    
govc library.deploy --pool="${GOVC_RESOURCE_POOL}" -ds=${GOVC_DATASTORE} ${OVA_library}/${OVA_name} ${master_name}02.${CLUSTER_DOMAIN}   
#govc vm.clone -vm rhcos-${OCP_RELEASE}-x86_64-vmware -annotation=MasterNode001 -c=${MASTER_CPU} -m=${MASTER_MEMORY} -net ${GOVC_NETWORK} -net.address 00:50:56:8c:a6:01 -on=false -folder=${GOVC_FOLDER} -datastore-cluster=${GOVC_DATASTORE} -pool=${GOVC_RESOURCE_POOL} ${master_name}00.${CLUSTER_DOMAIN}
#govc vm.clone -vm rhcos-${OCP_RELEASE}-x86_64-vmware -annotation=MasterNode002 -c=${MASTER_CPU} -m=${MASTER_MEMORY} -net ${GOVC_NETWORK} -net.address 00:50:56:8c:a6:02 -on=false -folder=${GOVC_FOLDER} -datastore-cluster=${GOVC_DATASTORE} -pool=${GOVC_RESOURCE_POOL} ${master_name}01.${CLUSTER_DOMAIN}
#govc vm.clone -vm rhcos-${OCP_RELEASE}-x86_64-vmware -annotation=MasterNode003 -c=${MASTER_CPU} -m=${MASTER_MEMORY} -net ${GOVC_NETWORK} -net.address 00:50:56:8c:a6:03 -on=false -folder=${GOVC_FOLDER} -datastore-cluster=${GOVC_DATASTORE} -pool=${GOVC_RESOURCE_POOL} ${master_name}02.${CLUSTER_DOMAIN}

govc vm.change -c=${MASTER_CPU} -m=${MASTER_MEMORY} -vm=${master_name}00.${CLUSTER_DOMAIN}
govc vm.change -c=${MASTER_CPU} -m=${MASTER_MEMORY} -vm=${master_name}01.${CLUSTER_DOMAIN}
govc vm.change -c=${MASTER_CPU} -m=${MASTER_MEMORY} -vm=${master_name}02.${CLUSTER_DOMAIN}


govc vm.disk.change -vm ${master_name}00.${CLUSTER_DOMAIN} -size 120GB
govc vm.disk.change -vm ${master_name}01.${CLUSTER_DOMAIN} -size 120GB
govc vm.disk.change -vm ${master_name}02.${CLUSTER_DOMAIN} -size 120GB


govc vm.network.change  -net ${VMWARE_SWITCH}${GOVC_NETWORK}  -vm=${master_name}00.${CLUSTER_DOMAIN} ethernet-0
govc vm.network.change  -net ${VMWARE_SWITCH}${GOVC_NETWORK}  -vm=${master_name}01.${CLUSTER_DOMAIN} ethernet-0
govc vm.network.change  -net ${VMWARE_SWITCH}${GOVC_NETWORK}  -vm=${master_name}02.${CLUSTER_DOMAIN} ethernet-0


master=$(cat ${IGNITION_PATH}/master.ign | base64 -w0)

govc vm.change -e="guestinfo.ignition.config.data=${master}" -vm=${master_name}00.${CLUSTER_DOMAIN}
govc vm.change -e="guestinfo.ignition.config.data=${master}" -vm=${master_name}01.${CLUSTER_DOMAIN}
govc vm.change -e="guestinfo.ignition.config.data=${master}" -vm=${master_name}02.${CLUSTER_DOMAIN}


govc vm.change -e="guestinfo.ignition.config.data.encoding=base64" -vm=${master_name}00.${CLUSTER_DOMAIN}
govc vm.change -e="guestinfo.ignition.config.data.encoding=base64" -vm=${master_name}01.${CLUSTER_DOMAIN}
govc vm.change -e="guestinfo.ignition.config.data.encoding=base64" -vm=${master_name}02.${CLUSTER_DOMAIN}


govc vm.change -e="disk.EnableUUID=TRUE" -vm=${master_name}00.${CLUSTER_DOMAIN}
govc vm.change -e="disk.EnableUUID=TRUE" -vm=${master_name}01.${CLUSTER_DOMAIN}
govc vm.change -e="disk.EnableUUID=TRUE" -vm=${master_name}02.${CLUSTER_DOMAIN}


govc vm.change -e="guestinfo.afterburn.initrd.network-kargs=ip=${master1_ip}::${ocp_net_gw}:${ocp_net_mask}:${master_name}00.${CLUSTER_DOMAIN}:ens192:off nameserver=${ocp_net_dns}" -vm=${master_name}00.${CLUSTER_DOMAIN}
govc vm.change -e="guestinfo.afterburn.initrd.network-kargs=ip=${master2_ip}::${ocp_net_gw}:${ocp_net_mask}:${master_name}01.${CLUSTER_DOMAIN}:ens192:off nameserver=${ocp_net_dns}" -vm=${master_name}01.${CLUSTER_DOMAIN}
govc vm.change -e="guestinfo.afterburn.initrd.network-kargs=ip=${master3_ip}::${ocp_net_gw}:${ocp_net_mask}:${master_name}02.${CLUSTER_DOMAIN}:ens192:off nameserver=${ocp_net_dns}" -vm=${master_name}02.${CLUSTER_DOMAIN}






#Worker Nodes


govc library.deploy --pool="${GOVC_RESOURCE_POOL}" -ds=${GOVC_DATASTORE} ${OVA_library}/${OVA_name} ${worker_name}00.${CLUSTER_DOMAIN}  
govc library.deploy --pool="${GOVC_RESOURCE_POOL}" -ds=${GOVC_DATASTORE} ${OVA_library}/${OVA_name} ${worker_name}01.${CLUSTER_DOMAIN} 
govc library.deploy --pool="${GOVC_RESOURCE_POOL}" -ds=${GOVC_DATASTORE} ${OVA_library}/${OVA_name} ${worker_name}02.${CLUSTER_DOMAIN} 
#govc vm.clone -vm rhcos-${OCP_RELEASE}-x86_64-vmware -annotation=WorkerNode001 -c=${WORKER_CPU} -m=${WORKER_MEMORY} -net ${GOVC_NETWORK} -net.address 00:50:56:8c:a6:11 -on=false -folder=${GOVC_FOLDER} -datastore-cluster=${GOVC_DATASTORE} -pool=${GOVC_RESOURCE_POOL} ${worker_name}00.${CLUSTER_DOMAIN}
#govc vm.clone -vm rhcos-${OCP_RELEASE}-x86_64-vmware -annotation=WorkerNode002 -c=${WORKER_CPU} -m=${WORKER_MEMORY} -net ${GOVC_NETWORK} -net.address 00:50:56:8c:a6:12 -on=false -folder=${GOVC_FOLDER} -datastore-cluster=${GOVC_DATASTORE} -pool=${GOVC_RESOURCE_POOL} ${worker_name}01.${CLUSTER_DOMAIN}
#govc vm.clone -vm rhcos-${OCP_RELEASE}-x86_64-vmware -annotation=WorkerNode003 -c=${WORKER_CPU} -m=${WORKER_MEMORY} -net ${GOVC_NETWORK} -net.address 00:50:56:8c:a6:13 -on=false -folder=${GOVC_FOLDER} -datastore-cluster=${GOVC_DATASTORE} -pool=${GOVC_RESOURCE_POOL} ${worker_name}02.${CLUSTER_DOMAIN}


govc vm.change -c=${WORKER_CPU} -m=${WORKER_MEMORY} -vm=${worker_name}00.${CLUSTER_DOMAIN}
govc vm.change -c=${WORKER_CPU} -m=${WORKER_MEMORY} -vm=${worker_name}01.${CLUSTER_DOMAIN}
govc vm.change -c=${WORKER_CPU} -m=${WORKER_MEMORY} -vm=${worker_name}02.${CLUSTER_DOMAIN}


govc vm.disk.change -vm ${worker_name}00.${CLUSTER_DOMAIN} -size 120GB
govc vm.disk.change -vm ${worker_name}01.${CLUSTER_DOMAIN} -size 120GB
govc vm.disk.change -vm ${worker_name}02.${CLUSTER_DOMAIN} -size 120GB



govc vm.network.change  -net ${VMWARE_SWITCH}${GOVC_NETWORK}  -vm=${worker_name}00.${CLUSTER_DOMAIN} ethernet-0
govc vm.network.change  -net ${VMWARE_SWITCH}${GOVC_NETWORK}  -vm=${worker_name}01.${CLUSTER_DOMAIN} ethernet-0
govc vm.network.change  -net ${VMWARE_SWITCH}${GOVC_NETWORK}  -vm=${worker_name}02.${CLUSTER_DOMAIN} ethernet-0

worker=$(cat ${IGNITION_PATH}/worker.ign | base64 -w0)

govc vm.change -e="guestinfo.ignition.config.data=${worker}" -vm=${worker_name}00.${CLUSTER_DOMAIN}
govc vm.change -e="guestinfo.ignition.config.data=${worker}" -vm=${worker_name}01.${CLUSTER_DOMAIN}
govc vm.change -e="guestinfo.ignition.config.data=${worker}" -vm=${worker_name}02.${CLUSTER_DOMAIN}


govc vm.change -e="guestinfo.ignition.config.data.encoding=base64" -vm=${worker_name}00.${CLUSTER_DOMAIN}
govc vm.change -e="guestinfo.ignition.config.data.encoding=base64" -vm=${worker_name}01.${CLUSTER_DOMAIN}
govc vm.change -e="guestinfo.ignition.config.data.encoding=base64" -vm=${worker_name}02.${CLUSTER_DOMAIN}


govc vm.change -e="disk.EnableUUID=TRUE" -vm=${worker_name}00.${CLUSTER_DOMAIN}
govc vm.change -e="disk.EnableUUID=TRUE" -vm=${worker_name}01.${CLUSTER_DOMAIN}
govc vm.change -e="disk.EnableUUID=TRUE" -vm=${worker_name}02.${CLUSTER_DOMAIN}


govc vm.change -e="guestinfo.afterburn.initrd.network-kargs=ip=${worker1_ip}::${ocp_net_gw}:${ocp_net_mask}:${worker_name}00.${CLUSTER_DOMAIN}:ens192:off nameserver=${ocp_net_dns}" -vm=${worker_name}00.${CLUSTER_DOMAIN}
govc vm.change -e="guestinfo.afterburn.initrd.network-kargs=ip=${worker2_ip}::${ocp_net_gw}:${ocp_net_mask}:${worker_name}01.${CLUSTER_DOMAIN}:ens192:off nameserver=${ocp_net_dns}" -vm=${worker_name}01.${CLUSTER_DOMAIN}
govc vm.change -e="guestinfo.afterburn.initrd.network-kargs=ip=${worker3_ip}::${ocp_net_gw}:${ocp_net_mask}:${worker_name}02.${CLUSTER_DOMAIN}:ens192:off nameserver=${ocp_net_dns}" -vm=${worker_name}02.${CLUSTER_DOMAIN}





###################################
# Start VMs

govc vm.power -on ${bootstrap_name}.${CLUSTER_DOMAIN}


govc vm.power -on ${master_name}00.${CLUSTER_DOMAIN}
govc vm.power -on ${master_name}01.${CLUSTER_DOMAIN}
govc vm.power -on ${master_name}02.${CLUSTER_DOMAIN}


govc vm.power -on ${worker_name}00.${CLUSTER_DOMAIN}
govc vm.power -on ${worker_name}01.${CLUSTER_DOMAIN}
govc vm.power -on ${worker_name}02.${CLUSTER_DOMAIN}
