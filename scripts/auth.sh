#!/bin/bash

PULL_SECRET="secrets/pull-secret.json"
REGISTRY_PULL_SECRET="secrets/registry-pull-secret.json"
MAIN_PULL_SECRET="secrets/main-pull-secret.json"

oc registry login --to ${REGISTRY_PULL_SECRET}

jq -s '.[0] * .[1]' ${MAIN_PULL_SECRET} ${REGISTRY_PULL_SECRET} > ${PULL_SECRET}
