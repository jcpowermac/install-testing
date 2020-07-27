#!/bin/bash

PULL_SECRET="secrets/pull-secret.json"
REGISTRY_PULL_SECRET="secrets/registry-pull-secret.json"
MAIN_PULL_SECRET="secrets/main-pull-secret.json"
TEMP_PULL_SECRET="secrets/temp-pull-secret.json"
VERSION=4.5
#VERSION=4.5.0-0.ci-2020-04-20-144713
PROJECT=ocp
TO_IMAGE=quay.io/jcallen/origin-release:v${VERSION}
#TO_IMAGE=quay.io/jcallen/origin-release:${VERSION}
#TO_IMAGE=origin-release:v${VERSION}

export QUAY_AUTH=""

echo "************************************"
echo "********** ${VERSION} **************"


rm openshift-client-*
rm openshift-install-*


oc registry login --to ${REGISTRY_PULL_SECRET}

jq '.auths["quay.io"].auth=env.QUAY_AUTH' ${MAIN_PULL_SECRET} > ${TEMP_PULL_SECRET}
#jq 'del(.auths["quay.io"].email)'

#jq -c -s '.[0] * .[1]' ${MAIN_PULL_SECRET} ${REGISTRY_PULL_SECRET} > ${PULL_SECRET}
jq -c -s '.[0] * .[1]' ${TEMP_PULL_SECRET} ${REGISTRY_PULL_SECRET} > ${PULL_SECRET}

oc adm release new -a ${PULL_SECRET} -n ocp --server https://api.ci.openshift.org \
                                --from-image-stream "${VERSION}" \
                                --to-image "${TO_IMAGE}" \
                                machine-config-operator=quay.io/jcallen/origin-machine-config-operator:latest

                                #machine-api-operator=quay.io/jcallen/origin-machine-api-operator:latest
