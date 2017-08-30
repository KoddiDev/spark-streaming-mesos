#!/usr/bin/env bash

# Builds a universe for this spark package, and uploads it to S3.
#
# Manifest config:
#   cli_version - version label to use for CLI package
#   spark_uri - where fetch spark distribution from (or SPARK_DIST_URI if provided)
#
# ENV vars:
#   DIST (optional) - if "dev", spark will be built from source rather than
#                     using the distribution specified in manifest.json.
#   DOCKER_IMAGE (optional) - "<image>:<version>", falls back to mesosphere/spark-dev:COMMIT)
#   COMMONS_TOOLS_DIR (optional) - path to dcos-commons/tools/, or empty to fetch latest release tgz
#   ghprbActualCommit / GIT_COMMIT (optional) - COMMIT value to use for DOCKER_IMAGE, if DOCKER_IMAGE isn't specified

set -e -x -o pipefail


echo "starting universe.sh"

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SPARK_BUILD_DIR="${DIR}/.."
SPARK_DIR="${DIR}/../../spark"

# set CLI_VERSION, DOCKER_IMAGE:
configure_env() {
    echo "configure_env: start"
    CLI_VERSION=$(jq ".cli_version" "${SPARK_BUILD_DIR}/manifest.json")
    CLI_VERSION="${CLI_VERSION%\"}"
    CLI_VERSION="${CLI_VERSION#\"}"
    echo "Using CLI Version: $CLI_VERSION"
    if [ -z "$DOCKER_IMAGE" ]; then
        # determine image label based on git commit:
        if [ -n "$ghprbActualCommit" ]; then
            # always overrides default GIT_COMMIT:
            GIT_COMMIT=$ghprbActualCommit
        fi
        if [ -z "$GIT_COMMIT" ]; then
            # Commit not explicitly provided by CI. Fetch directly from Git:
            GIT_COMMIT="$(git rev-parse HEAD)"
        fi
        if [ -z "$GIT_COMMIT" ]; then
            echo "Unable to determine git commit. Giving up."
            exit 1
        fi
        DOCKER_IMAGE="mesosphere/spark-dev:$GIT_COMMIT"
        echo "Using Docker image: $DOCKER_IMAGE"
    fi
}

make_docker() {
    echo "make_docker: start"
    (cd "${SPARK_BUILD_DIR}" && DOCKER_IMAGE=${DOCKER_IMAGE} make docker)
}

upload_cli_and_stub_universe() {
    echo "upload_cli_and_stub_universe: start"
    # Build/upload package using custom template parameters: TEMPLATE_X_Y_Z => {{x-y-z}}
    TEMPLATE_CLI_VERSION=${CLI_VERSION} \
    TEMPLATE_SPARK_DIST_URI=$(default_spark_dist) \
    TEMPLATE_DOCKER_IMAGE=${DOCKER_IMAGE} \
        ${COMMONS_TOOLS_DIR}/ci_upload.py \
            spark \
            ${SPARK_BUILD_DIR}/universe/ \
            ${SPARK_BUILD_DIR}/cli/dcos-spark/dcos-spark-darwin \
            ${SPARK_BUILD_DIR}/cli/dcos-spark/dcos-spark-linux \
            ${SPARK_BUILD_DIR}/cli/dcos-spark/dcos-spark.exe \
            ${SPARK_BUILD_DIR}/cli/python/dist/*.whl

}

source "${SPARK_BUILD_DIR}/bin/jenkins.sh"
export COMMONS_TOOLS_DIR=${DIR}/dcos-commons-tools/
configure_env
make_docker
upload_cli_and_stub_universe
