#!/bin/bash

name=vmc
NAMESPACE=jcallen-vmc
ARTIFACTS=/var/home/jlcallen/Development/openshift-install-testing/vmware/artifacts

# NOTE: This must be $name-cluster-profile
SECRETS="/var/home/jlcallen/Development/openshift-install-testing/vmware/${name}-cluster-profile"
RELEASE=/var/home/jlcallen/Development/release
CONFIG=${RELEASE}/ci-operator/config/openshift/installer/openshift-installer-release-4.3.yaml
TEMPLATE=${RELEASE}/ci-operator/templates/openshift/installer/cluster-launch-installer-upi-e2e.yaml
CLUSTER_TYPE=vsphere


oc project ${NAMESPACE}
oc delete is --all
oc delete secret "${name}-cluster-profile"
rm -Rf artifacts/

mkdir artifacts/ "$name-cluster-profile"/

export CLUSTER_TYPE JOB_NAME_SAFE=$name TEST_COMMAND="TEST_SUITE=openshift/conformance/parallel run-tests"
ci-operator \
    --artifact-dir ${ARTIFACTS} \
    --config ${CONFIG} \
    --git-ref jcpowermac/installer@vmware_on_aws \
    --template ${TEMPLATE} \
    --secret-dir "${SECRETS}/" \
    --namespace ${NAMESPACE}
