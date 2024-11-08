#!/bin/sh

set -e
set -o errexit -o nounset

ARCH=${1}
ARCH_FOUND=0
VALID_ARCHS="amd64 arm64"

for VALID_ARCH in ${VALID_ARCHS}; do
    if [ "${ARCH}" = "${VALID_ARCH}" ]; then
        ARCH_FOUND=1
        break
    fi
done

if [ ${ARCH_FOUND} -eq 0 ]; then
    echo "arch '${ARCH}' is not allowed. Valid archs are: ${VALID_ARCHS}"
    exit 1
fi
