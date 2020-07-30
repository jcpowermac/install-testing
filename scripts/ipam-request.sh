#!/bin/bash

cluster_name="test"
base_domain="devcluster.openshift.com"
cluster_domain="${cluster_name}.${base_domain}"
ipam_json_filename=ipam.auto.tfvars.json
ipam_token=e43f96014460c69898d1cf4fbd35df04eda8e19c
ipam_ip_address=172.31.254.20
ipam_port=8080
prefix="172.31.248.0/23"

set +x

function allocate_ip() {
    set +x
    args=$(jq -c -n \
        --arg fqdn "$1" \
        --arg tag "$cluster_name" \
        '{dns_name: $fqdn,tags: [$tag]}')

    results=$(curl \
        -H "Authorization: Token ${ipam_token}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json; indent=4" \
        --request POST \
        --data "${args}" \
        "http://${ipam_ip_address}:${ipam_port}/api/ipam/prefixes/${prefix_id}/available-ips/")

    ipaddr=$(echo ${results} | jq -r '.address' | awk -F/ '{print $1}')
}

function get_prefix_id() {
    results=$(curl \
        -H "Authorization: Token ${ipam_token}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json; indent=4" \
        --request GET \
        --data "${args}" \
        "http://${ipam_ip_address}:${ipam_port}/api/ipam/prefixes/?prefix=${prefix}")


    prefix_id=$(echo ${results} | jq -r '.results[0].id' )
}


# Generate empty JSON strings
compute=$(jq -c -n '{compute_ips:[],compute_ip_addresses:[]}')
bootstrap=$(jq -c -n '{bootstrap_ip:"",bootstrap_ip_address:""}')
control_plane=$(jq -c -n '{control_plane_ips:[],control_plane_ip_addresses:[]}')
lb=$(jq -c -n '{lb_ip_address:""}')

prefix_id=$(http http://${ipam_ip_address}:${ipam_port}/api/ipam/prefixes/\?prefix\=${prefix} Authorization:"Token ${ipam_token}" | jq -r '.results[0].id')

echo "$(date -u --rfc-3339=seconds) - Allocating bootstrap ip address..."
allocate_ip "bootstrap-0.${cluster_name}.${base_domain}"
bootstrap=$(echo $bootstrap | jq -c --arg ip $ipaddr '.bootstrap_ip_address = $ip')
bootstrap=$(echo $bootstrap | jq -c --arg ip $ipaddr '.bootstrap_ip = $ip')

echo "$(date -u --rfc-3339=seconds) - Allocating lb ip address..."
allocate_ip "lb-0.${cluster_name}.${base_domain}"
lb=$(echo $lb | jq -c --arg ip $ipaddr '.lb_ip_address = $ip')

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


