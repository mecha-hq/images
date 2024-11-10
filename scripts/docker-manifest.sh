#!/bin/sh

set -e
set -o errexit -o nounset

REGISTRY=${1}
OWNER=${2}
IMAGE=${3}
VERSION=${4}
ARCH=${5}

if [ -z "${REGISTRY}" ]; then echo "Argument 1 (REGISTRY) is required"; exit 1; fi
if [ -z "${OWNER}" ]; then echo "Argument 2 (OWNER) is required"; exit 1; fi
if [ -z "${IMAGE}" ]; then echo "Argument 3 (IMAGE) is required"; exit 1; fi
if [ -z "${VERSION}" ]; then echo "Argument 4 (VERSION) is required"; exit 1; fi
if [ -z "${ARCH}" ]; then echo "Argument 5 (ARCH) is required"; exit 1; fi

manifests=""
for a in "${ARCH//,/ }"; do
    manifests="${manifests} ${REGISTRY}/${OWNER}/${IMAGE}:${VERSION}-$a"
done

docker manifest create "${REGISTRY}/${OWNER}/${IMAGE}:${VERSION}" $manifests

for a in "${ARCH//,/ }"; do
    docker manifest annotate --arch $a --os linux \
        "${REGISTRY}/${OWNER}/${IMAGE}:${VERSION}" \
        "${REGISTRY}/${OWNER}/${IMAGE}:${VERSION}-$a";
done
