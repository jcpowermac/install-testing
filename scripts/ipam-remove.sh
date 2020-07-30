#!/bin/bash


# NOTE:
# The netbox API **** requires **** a slash / at the end of the URI
# If there is no slash you will receive no results or errors
# except when using ?= query

cluster_name="test"
base_domain="devcluster.openshift.com"
cluster_domain="${cluster_name}.${base_domain}"
ipam_json_filename=ipam.auto.tfvars.json
ipam_token=e43f96014460c69898d1cf4fbd35df04eda8e19c
ipam_ip_address=172.31.254.20
ipam_port=8080
prefix="172.31.248.0/23"

function delete_ip() {
    results=$(curl \
        -H "Authorization: Token ${ipam_token}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json; indent=4" \
        --request DELETE \
        "http://${ipam_ip_address}:${ipam_port}/api/ipam/ip-addresses/${id}/")
}

function ipam_ip_addresses_id() {

    results=$(curl \
        -H "Authorization: Token ${ipam_token}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json; indent=4" \
        "http://${ipam_ip_address}:${ipam_port}/api/ipam/ip-addresses/?tag=${cluster_name}")

    ip_address_ids=$(echo ${results} | jq -r '.results[].id')
}

ipam_ip_addresses_id

for id in ${ip_address_ids};
do
	echo "deleting id: ${id}"
    delete_ip
done
