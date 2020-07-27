#!/bin/bash

OC=../oc

#export OPENSHIFT_INSTALL_RELEASE_IMAGE_OVERRIDE="quay.io/jcallen/origin-release:v4.4"
TERRAFORM_BIN=$PWD/../terraform



set -xe
export AWS_PROFILE="openshift-dev"
export AWS_DEFAULT_REGION=us-east-2
export KUBECONFIG=${PWD}/auth/kubeconfig
#export TF_LOG=DEBUG

#TERRAFORM="${GOPATH}/src/github.com/openshift/installer/upi/vsphere/packet"
#IGNITION="${GOPATH}/src/github.com/openshift/installer/upi/vsphere/packet"
#TFVARS="${GOPATH}/src/github.com/openshift/installer/upi/vsphere/packet/terraform.tfvars"
TERRAFORM="/home/jcallen/Development/installer/upi/vsphere"
IGNITION="/home/jcallen/Development/installer/upi/vsphere"
TFVARS="/home/jcallen/Development/installer/upi/vsphere/terraform.tfvars"

(cd ${TERRAFORM} && ${TERRAFORM_BIN} init)
(cd ${TERRAFORM} && ${TERRAFORM_BIN} destroy -refresh=false -auto-approve -var-file=${TFVARS})

