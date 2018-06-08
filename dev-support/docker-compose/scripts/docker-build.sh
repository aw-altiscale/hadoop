#!/usr/bin/env bash

HADOOP_BASE=$(cd -P -- "$(dirname -- "${BASH_SOURCE-$0}")/../../.." >/dev/null && pwd -P)
DCH=${HADOOP_BASE}/dev-support/docker-compose
HADOOP_VERSION=$(grep '<version>' "${HADOOP_BASE}/pom.xml" \
    | head -1 \
    | sed  -e 's|^ *<version>||' -e 's|</version>.*$||')

# bash 3.2.5+... strip last two characters
HADOOP_MINOR_VERSION=${HADOOP_VERSION:0:${#HADOOP_VERSION}-2}

CONSTRUCTED=/tmp/Dockerfile.$$

DOCKERIMAGE=$(docker images --format '{{.ID}}' "hadoop:${HADOOP_VERSION}")

PARENT=${HADOOP_BASE}

if [[ $1 == full ]] || [[  -z ${DOCKERIMAGE} ]]; then
  REBUILD_ALL=true
else
  REBUILD_ALL=false
fi

build_cmd() {
  # given a docker image tag, a Dockerfile, and the parent tag
  # generate a Dockerfile (replacing the FROM line) then build it
  tag=$1
  fn=$2
  fromtag=$3
  newfn="${CONSTRUCTED}"

  pushd "${PARENT}" > /dev/null || exit 1

  if [[ "${tag}" =~ stage ]]; then
    newfn=${fn}
  elif [[ -n "${fromtag}" ]]; then
    (
      echo "FROM ${fromtag}"
      grep -vi FROM "${fn}"
    ) > "${newfn}"
  else
    (
      echo "FROM hadoop:${HADOOP_VERSION}"
      grep -vi FROM "${fn}"
    ) > "${newfn}"
  fi

  echo ""
  echo "**** Building ${tag} ****"
  echo ""

  docker build \
    --build-arg HADOOP_VERSION="${HADOOP_VERSION}" \
    --build-arg HADOOP_MINOR_VERSION="${HADOOP_MINOR_VERSION}" \
    -t "${tag}" \
    -f "${newfn}" \
    .
  retval=$?
  popd > /dev/null || exit 1

  if [[ ${retval} -gt 0 ]]; then
    echo "ERROR: cannot build ${fn}"
    exit 1
  fi
}

build_bundled() {

  # take the bundled Dockerfile, strip until the YETUS
  # line (since everything past that isn't needed to build
  # hadoop), bump the default maven opts up to 2g, then build it as stage1
  new=$1
  df="${HADOOP_BASE}/dev-support/docker/Dockerfile"
  lines=$(grep -n 'YETUS CUT HERE' "${df}" | cut -f1 -d:)
  (
    if [[ -z "${lines}" ]]; then
     cat "${df}"
    else
      head -n "${lines}" "${df}"
    fi
  ) | sed -e '/MAVEN_OPTS/ s,x512m,x2g,' > "${new}"

  build_cmd "hadoop-stage1:${HADOOP_VERSION}" "${new}"

   # now build the builder image off of stage1
  USER_NAME=${SUDO_USER:=$USER}
  USER_ID=$(id -u "${USER_NAME}")
  GROUP_ID=$(id -g "${USER_NAME}")

   cat > "${CONSTRUCTED}" <<EOF
FROM hadoop-stage1:${HADOOP_VERSION}
RUN groupadd --non-unique -g ${GROUP_ID} ${USER_NAME}
RUN useradd -g ${GROUP_ID} -u ${USER_ID} -m ${USER_NAME}
RUN chown -R ${USER_NAME} /home/${USER_NAME}
ENV HOME /home/${USER_NAME}
EOF

  build_cmd "hadoop-stage2:${HADOOP_VERSION}" "${CONSTRUCTED}"

  echo ""
  echo "**** Building hadoop ${HADOOP_VERSION} ****"
  echo ""

  # Build Hadoop
  docker run -i -t \
    -v "${HADOOP_BASE}:/opt/hadoop-src" \
    -v "${HOME}/.m2:/home/${USER_NAME}/.m2" \
    -w /opt/hadoop-src \
    -u "${USER_NAME}" \
    hadoop-stage2:"${HADOOP_VERSION}" \
    mvn -Pdist -Pnative -Dmaven.javadoc.skip -DskipTests -Dtar clean install

}

if [[ ${REBUILD_ALL} == true ]]; then

  for node in nn dn rm nm httpfs hive spark krb stage1 stage2 ; do
    docker rmi hadoop-${node}:${HADOOP_VERSION}
  done

  # build hadoop's dev environment
  build_bundled "${CONSTRUCTED}"

  # Build the base image, which has the local bits and will install our
  # built Hadoop inside it by copying the tarball, reducing the image size
  # tremendously by using the stage2 image
  build_cmd "hadoop:${HADOOP_VERSION}" "${DCH}/scripts/Dockerfile" "hadoop-stage1:${HADOOP_VERSION}"


fi

PARENT=${DCH}

build_cmd "hadoop-krb:${HADOOP_VERSION}" "kerberos/Dockerfile"

# build the nodes
for node in nn dn rm nm httpfs hive spark ; do
  build_cmd "hadoop-${node}:${HADOOP_VERSION}" "scripts/Dockerfile-${node}" "hadoop:${HADOOP_VERSION}"
done
