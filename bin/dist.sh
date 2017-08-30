#!/bin/bash

# Builds a spark distribution.
#
# Assumes: Spark source directory exists at "../../spark".
# Output: build/spark/spark-XYZ.tgz

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${DIR}/common.sh"

# Writes a Spark distribution to ${SPARK_BUILD_DIR}/build/dist/spark-*.tgz
function make_distribution {
    local HADOOP_VERSION=${HADOOP_VERSION:-$(default_hadoop_version)}

    rm -rf "${DIST_DIR}"
    mkdir -p "${DIST_DIR}"

    if [[ "${DIST}" == "dev" ]]; then
        make_dev_distribution
    elif [[ "${DIST}" == "prod" ]]; then
        make_prod_distribution
    else
        make_manifest_distribution
    fi
}


function make_manifest_distribution {
    SPARK_DIST_URI=${SPARK_DIST_URI:-$(default_spark_dist)}
    (cd "${DIST_DIR}" && wget "${SPARK_DIST_URI}")
}

# Adapted from spark/dev/make-distribution.sh.
#
# Some python/R code from make-distribution.sh has not been included,
# so this distribution may not work with python/R.
function make_dev_distribution {
    pushd "${SPARK_DIR}"
    rm -rf spark-*.tgz

    ./build/sbt -Pmesos "-Phadoop-${HADOOP_VERSION}" -Phive -Phive-thriftserver package

    # jars
    rm -rf /tmp/spark-SNAPSHOT*
    mkdir -p /tmp/spark-SNAPSHOT/jars
    cp -r "${SPARK_DIR}"/assembly/target/scala*/jars/* /tmp/spark-SNAPSHOT/jars

    # examples/jars
    mkdir -p /tmp/spark-SNAPSHOT/examples/jars
    cp -r "${SPARK_DIR}"/examples/target/scala*/jars/* /tmp/spark-SNAPSHOT/examples/jars
    # Deduplicate jars that have already been packaged as part of the main Spark dependencies.
    for f in /tmp/spark-SNAPSHOT/examples/jars/*; do
        name=$(basename "$f")
        if [ -f "/tmp/spark-SNAPSHOT/jars/$name" ]; then
            rm "/tmp/spark-SNAPSHOT/examples/jars/$name"
        fi
    done

    # data
    cp -r "${SPARK_DIR}/data" /tmp/spark-SNAPSHOT/

    # conf
    mkdir -p /tmp/spark-SNAPSHOT/conf
    cp "${SPARK_DIR}"/conf/* /tmp/spark-SNAPSHOT/conf
    cp -r "${SPARK_DIR}/bin" /tmp/spark-SNAPSHOT
    cp -r "${SPARK_DIR}/sbin" /tmp/spark-SNAPSHOT
    cp -r "${SPARK_DIR}/python" /tmp/spark-SNAPSHOT

    (cd /tmp && tar czf spark-SNAPSHOT.tgz spark-SNAPSHOT)
    mkdir -p "${DIST_DIR}"
    cp /tmp/spark-SNAPSHOT.tgz "${DIST_DIR}"
    popd
}

function make_prod_distribution {
    pushd "${SPARK_DIR}"
    rm -rf spark-*.tgz

    if [ -f make-distribution.sh ]; then
        # Spark <2.0
        ./make-distribution.sh --tgz "-Phadoop-${HADOOP_VERSION}" -Phive -Phive-thriftserver -DskipTests
    else
        # Spark >=2.0
        if does_profile_exist "mesos"; then
            MESOS_PROFILE="-Pmesos"
        else
            MESOS_PROFILE=""
        fi
        ./dev/make-distribution.sh --tgz "${MESOS_PROFILE}" "-Phadoop-${HADOOP_VERSION}" -Psparkr -Phive -Phive-thriftserver -DskipTests
    fi

    mkdir -p "${DIST_DIR}"
    cp spark-*.tgz "${DIST_DIR}"

    popd
}

make_distribution
