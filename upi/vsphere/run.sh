#!/bin/bash

OC=../oc
TERRAFORM_BIN=$PWD/../terraform

#export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE="quay.io/jcallen/origin-release:v4.4"
#export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE="quay.io/jcallen/origin-release:v4.5"
TERRAFORM="/home/jcallen/Development/installer/upi/vsphere/"
IGNITION="/home/jcallen/Development/installer/upi/vsphere/"
TFVARS="/home/jcallen/Development/installer/upi/vsphere/terraform.tfvars"


cluster_name="jcallen7-12"
base_domain="devcluster.openshift.com"
cluster_domain="${cluster_name}.${base_domain}"
ipam_json_filename=ipam.auto.tfvars.json
ipam_token=
ipam_ip_address=127.0.0.1
ipam_port=8080

# function from release ci template
function update_image_registry() {
    set +x
    sleep 30
    while true; do
        ${OC} get configs.imageregistry.operator.openshift.io/cluster > /dev/null && break
        sleep 10;
    done
    ${OC} patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"managementState":"Managed","storage":{"emptyDir":{}}}}'
}

function approve_csrs() {
  sleep 30

  while true; do
      ${OC} get csr -ojson | jq -r '.items[] | select(.status == {} ) | .metadata.name' | xargs --no-run-if-empty ${OC} adm certificate approve || true
      sleep 15
  done
}

function allocate_ip() {
    set +x
    args=$(jq -c -n \
        --arg fqdn "$1" \
        --arg tag "$cluster_name" \
        '{dns_name: $fqdn,tags: [$tag]}')

    echo ${args}


    results=$(curl \
        -H "Authorization: Token ${ipam_token}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json; indent=4" \
        --request POST \
        --data "${args}" \
        "http://${ipam_ip_address}:${ipam_port}/api/ipam/prefixes/${prefix_id}/available-ips/")

    echo ${results}

    ipaddr=$(echo ${results} | jq -r '.address' | awk -F/ '{print $1}')
}

set +x

# Generate empty JSON strings
compute=$(jq -c -n '{compute_ips:[],compute_ip_addresses:[]}')
bootstrap=$(jq -c -n '{bootstrap_ip:"",bootstrap_ip_address:""}')
control_plane=$(jq -c -n '{control_plane_ips:[],control_plane_ip_addresses:[]}')
lb=$(jq -c -n '{lb_ip_address:""}')

prefix_id=$(http http://${ipam_ip_address}:${ipam_port}/api/ipam/prefixes/\?prefix\=172.31.252.0/22 Authorization:"Token ${ipam_token}" | jq -r '.results[0].id')

echo "$(date -u --rfc-3339=seconds) - Allocating bootstrap ip address..."
allocate_ip "bootstrap-0.${cluster_name}.${base_domain}"
bootstrap=$(echo $bootstrap | jq -c --arg ip $ipaddr '.bootstrap_ip_address = $ip')
bootstrap=$(echo $bootstrap | jq -c --arg ip $ipaddr '.bootstrap_ip = $ip')

echo "$(date -u --rfc-3339=seconds) - Allocating lb ip address..."
allocate_ip "lb-0.${cluster_name}.${base_domain}"
lb=$(echo $lb | jq -c --arg ip $ipaddr '.lb_ip_address = $ip')
#pause

echo "$(date -u --rfc-3339=seconds) - Allocating compute ip address..."
for i in $(seq 0 2)
do
    allocate_ip "compute-${i}.${cluster_name}.${base_domain}"

    compute=$(echo $compute | jq -c --arg ip $ipaddr '.compute_ips += [$ip]')
    compute=$(echo $compute | jq -c --arg ip $ipaddr '.compute_ip_addresses += [$ip]')

done

echo "$(date -u --rfc-3339=seconds) - Allocating control-plane ip address..."
for i in $(seq 0 2)
do
    allocate_ip "control-plane-${i}.${cluster_name}.${base_domain}"

    control_plane=$(echo $control_plane | jq -c --arg ip $ipaddr '.control_plane_ips += [$ip]')
    control_plane=$(echo $control_plane | jq -c --arg ip $ipaddr '.control_plane_ip_addresses += [$ip]')

done

echo "$(date -u --rfc-3339=seconds) - Generating JSON tfvars ..."
echo "${compute} ${control_plane} ${bootstrap} ${lb} " | jq -s add > "${ipam_json_filename}"


#exit 1

set -x
export AWS_PROFILE="openshift-dev"
export AWS_DEFAULT_REGION=us-east-2
export KUBECONFIG=${PWD}/auth/kubeconfig
#export TF_LOG=DEBUG


rm -Rf auth *.ign metadata.json .openshift_install*
(cd ${TERRAFORM} && rm -Rf *.ign .terraform terraform.tfstate terraform.tfstate.backup)
(cd ${IGNITION} && rm -Rf *.ign)

cp install-config{-backup-dev,}.yaml

set -e
../openshift-install create manifests --log-level debug
set +e

rm -f openshift/99_openshift-cluster-api_master-machines-*.yaml
rm -f openshift/99_openshift-cluster-api_worker-machineset-*.yaml
sed -i "s;mastersSchedulable: true;mastersSchedulable: false;g" manifests/cluster-scheduler-02-config.yml


../openshift-install create ignition-configs --log-level debug

cp *.ign ${IGNITION}
cp *tfvars* ${TERRAFORM}

set -e
(cd ${TERRAFORM} && ${TERRAFORM_BIN} init)
(cd ${TERRAFORM} && ${TERRAFORM_BIN} apply -auto-approve -var-file=${TFVARS})
set +e

../openshift-install wait-for bootstrap-complete --log-level debug


approve_csrs &
csrs_pid=$!

../openshift-install wait-for install-complete --log-level debug

sleep 30
update_image_registry



kill $csrs_pid
