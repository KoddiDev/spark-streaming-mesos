#!/bin/bash

# Env Vars:
#   GIT_BRANCH (assumed to have prefix "refs/tags/custom-")

set -e -x -o pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SPARK_BUILD_DIR=${DIR}/..

pushd "${SPARK_BUILD_DIR}"
VERSION=${GIT_BRANCH#origin/tags/custom-}
DIST_NAME="spark-${VERSION}" make dist
popd
