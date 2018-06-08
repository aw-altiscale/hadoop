#!/bin/bash

HADOOP_BASE=$(cd -P -- "$(dirname -- "${BASH_SOURCE-$0}")/../.." >/dev/null && pwd -P)
export HADOOP_COMPOSE_DIR=${HADOOP_BASE}/dev-support/docker-compose

# doing this in one step hides values
HADOOP_VERSION=$(grep '<version>' "${HADOOP_BASE}/pom.xml" \
    | head -1 \
    | sed  -e 's|^ *<version>||' -e 's|</version>.*$||')
export HADOOP_VERSION

hadoop_net=$(docker network ls | grep hadoop)
if [[ -z ${hadoop_net} ]]; then
  docker network create -d bridge hadoop
fi

pushd "${HADOOP_COMPOSE_DIR}"
docker-compose down
popd