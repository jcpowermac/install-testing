#!/bin/bash

PULL_SECRET="secrets/pull-secret.json"
REGISTRY_PULL_SECRET="secrets/registry-pull-secret.json"
MAIN_PULL_SECRET="secrets/main-pull-secret.json"
VERSION=4.5
#VERSION=4.2.13
PROJECT=ocp

echo "************************************"
echo "********** ${VERSION} **************"


rm openshift-client-*
rm openshift-install-*


#oc registry login --to ${REGISTRY_PULL_SECRET}
#
#jq -s '.[0] * .[1]' ${MAIN_PULL_SECRET} ${REGISTRY_PULL_SECRET} > ${PULL_SECRET}

oc adm release extract --tools registry.svc.ci.openshift.org/${PROJECT}/release:${VERSION} -a ${PULL_SECRET}

TAR=$(ls -1 *.gz)

for t in ${TAR}
do
    tar -xvf ${t}
done


rm release.txt
rm sha256sum.txt
rm README.md
rm *.tar.gz
