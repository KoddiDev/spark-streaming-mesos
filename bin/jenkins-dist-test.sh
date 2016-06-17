#!/bin/bash

export S3_BUCKET=spark-build
export S3_PREFIX=
export DOCKER_IMAGE=mesosphere/spark-dev:${GIT_COMMIT}

source jenkins.sh

upload_distribution
spark_test
