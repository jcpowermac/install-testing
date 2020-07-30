#!/usr/bin/env bash

# Original from mtnbikenc/oa-testing

set -euxo pipefail

source build_options.sh

echo "### Updating git clone of openshift installer ###"
unset GIT_DIR
unset GIT_WORK_TREE
if [ ! -d "${OPT_CLUSTER_DIR}/installer" ]; then
    git clone https://github.com/openshift/installer "${OPT_CLUSTER_DIR}/installer"
else
    export GIT_DIR=${OPT_CLUSTER_DIR}/installer/.git
    export GIT_WORK_TREE=${OPT_CLUSTER_DIR}/installer
    if [ -d "${GIT_DIR}/rebase-apply" ]; then
        rm -rf "${GIT_DIR}/rebase-apply"
    fi
    git reset --hard
    git clean -fdx
    git checkout master
    git pull --rebase
    git fetch --tags --prune
    git branch | grep -v "master" | xargs git branch -D || true
fi
export GIT_DIR=${OPT_CLUSTER_DIR}/installer/.git
export GIT_WORK_TREE=${OPT_CLUSTER_DIR}/installer

# Checkout a pull request
if [ -v OPT_INSTALLER_PRNUM ]; then
  if [ -v OPT_INSTALLER_BASE_BRANCH ]; then
    git checkout "${OPT_INSTALLER_BASE_BRANCH}"
  fi
  git checkout -b temp-merge

  for PRNUM in ${OPT_INSTALLER_PRNUM}
  do
    git fetch origin "pull/${PRNUM}/head:PR${PRNUM}"
    git merge "PR${PRNUM}" -m "Merging ${PRNUM}"
  done
fi

# Checkout a tag
if [ -v OPT_INSTALLER_TAG ]; then
    git checkout "${OPT_INSTALLER_TAG}"
fi

git describe
git --no-pager log --oneline -5
