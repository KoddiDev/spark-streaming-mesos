#!/bin/bash

set -e -x -o pipefail

# $1: hadoop version (e.g. "2.6")
function docker_image() {
    echo "${DOCKER_IMAGE}:${__spark_build_version}-hadoop-$1"
}

function publish_docker_images() {
    local NUM_SPARK_DIST=$(jq ".spark_dist | length" manifest.json)
    local NUM_SPARK_DIST=$(expr ${NUM_SPARK_DIST} - 1)
    for i in $(seq 0 ${NUM_SPARK_DIST});
    do
        local HADOOP_VERSION=$(jq -r ".spark_dist[${i}].hadoop_version" manifest.json)

        SPARK_DIST_URI=$(jq -r ".spark_dist[${i}].uri" manifest.json) \
                      DOCKER_IMAGE="$(docker_image ${HADOOP_VERSION})" \
                      make docker
    done
}

function make_universe() {
    DOCKER_BUILD=false \
                DOCKER_IMAGE="$(docker_image $(default_hadoop_version))" \
                SPARK_DIST_URI=$(default_spark_dist) \
                make universe
}

function write_properties() {
    cp "${WORKSPACE}/stub-universe.properties" ../build.properties
    echo "RELEASE_VERSION=${__spark_build_version}" >> ../build.properties
}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SPARK_BUILD_DIR=${DIR}/../../spark-build
__spark_build_version=${GIT_BRANCH#origin/tags/}
source "${DIR}/jenkins.sh"

pushd "${SPARK_BUILD_DIR}"
SPARK_VERSION=$(jq -r ".spark_version" manifest.json)
docker_login
publish_docker_images
make_universe
write_properties
popd
