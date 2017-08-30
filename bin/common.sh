#!/usr/bin/env bash

set -o pipefail -o nounset -o errexit

__dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
__spark_build_dir="${__dir}/.."
__dist_dir="${__spark_build_dir}/build/dist"

function default_hadoop_version {
    jq -r ".default_spark_dist.hadoop_version" "${__spark_build_dir}/manifest.json"
}

function default_spark_dist {
    jq -r ".default_spark_dist.uri" "${__spark_build_dir}/manifest.json"
}

function check_env {
    echo "Checking environment..."
    # Check env early, before starting the cluster:
    missing_vars=false
    for env_var in "$@"; do
        if [ -z "${!env_var}" ]; then
            missing_vars=true
            echo "Missing required env: $env_var"
        fi
    done
    if $missing_vars; then
        echo "One or more required env not set! See above"
        exit 1
    fi
}

function docker_login {
    docker login --email=docker@mesosphere.io --username="${DOCKER_USERNAME}" --password="${DOCKER_PASSWORD}"
}

function set_hadoop_versions {
    HADOOP_VERSIONS=( "2.4" "2.6" "2.7" )
}

function build_and_test() {
    DIST=prod make dist
    SPARK_DIST=$(cd ${SPARK_HOME} && ls spark-*.tgz)
    S3_URL="s3://${S3_BUCKET}/${S3_PREFIX}/spark/${GIT_COMMIT}/" upload_to_s3

    SPARK_DIST_URI="http://${S3_BUCKET}.s3.amazonaws.com/${S3_PREFIX}/spark/${GIT_COMMIT}/${SPARK_DIST}" make universe

    export $(cat "${WORKSPACE}/stub-universe.properties")
    make test
}

# $1: profile (e.g. "hadoop-2.6")
function does_profile_exist() {
    (cd "${SPARK_HOME}" && ./build/mvn help:all-profiles | grep "$1")
}
