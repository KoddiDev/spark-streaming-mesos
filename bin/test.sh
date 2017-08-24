#!/usr/bin/env bash

# Spins up a DCOS cluster and runs tests against it

set -e
set -x
set -o pipefail

BIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SPARK_BUILD_DIR="${BIN_DIR}/.."
COMMONS_DIR=${BIN_DIR}/dcos-commons-tools/

check_env() {
    echo "Checking environment"
    # Check env early, before starting the cluster:
    if [ -z "$AWS_ACCESS_KEY_ID" \
            -o -z "$AWS_SECRET_ACCESS_KEY" \
            -o -z "$S3_BUCKET" \
            -o -z "$S3_PREFIX" \
            -o -z "$TEST_JAR_PATH" \
            -o -z "$COMMONS_DIR" ]; then
       echo "Missing required env. See check in ${BIN_DIR}/test.sh."
       echo "Environment:"
       env
       exit 1
    fi
}

build_scala_test_jar() {
    (cd tests/jobs/scala && sbt assembly)
}

setup_env() {
    python3 -m venv env
    . env/bin/activate
    pip3 install -r ${SPARK_BUILD_DIR}/tests/requirements.txt
}

start_cluster() {
    if [ -n "${DCOS_URL}" ]; then
        echo "Using existing cluster: $DCOS_URL"
    else
        echo "Launching new cluster"
        CCM_JSON=$(CCM_AGENTS=5 ${COMMONS_DIR}/launch_ccm_cluster.py)
        DCOS_URL=$(echo "${CCM_JSON}" | jq .url)
        if [ $? -ne 0 -o "$DCOS_URL" = "http://" ]; then
            exit 1
        fi
    fi
}

configure_cli() {
    dcos config set core.dcos_url $DCOS_URL
    dcos config set core.ssl_verify false
    dcos config set core.timeout 5
}

initialize_service_account() {
    if [ "$SECURITY" = "strict" ]; then
        ${COMMONS_DIR}/setup_permissions.sh root "*"
        ${COMMONS_DIR}/setup_permissions.sh root hdfs-role
    fi
}

run_tests() {
    set +e
    pushd ${SPARK_BUILD_DIR}
    SCALA_TEST_JAR_PATH=${SPARK_BUILD_DIR}/tests/jobs/scala/target/scala-2.11/dcos-spark-scala-tests-assembly-0.1-SNAPSHOT.jar \
        CLUSTER_URL=${DCOS_URL} \
        STUB_UNIVERSE_URL=${STUB_UNIVERSE_URL} \
        py.test -vv -m sanity tests/
    popd
    set -e
}

check_env
build_scala_test_jar
setup_env
start_cluster
configure_cli
initialize_service_account
run_tests
