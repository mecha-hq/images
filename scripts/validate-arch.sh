#!/bin/sh

set -e
set -o errexit -o nounset

ARCH=$(echo "${1}" | sed "s/,/ /g")
VALID_ARCHS="amd64 arm64"

for a in ${ARCH}; do
    ARCH_FOUND=0
    for VALID_ARCH in ${VALID_ARCHS}; do
        if [ "${a}" = "${VALID_ARCH}" ]; then
            ARCH_FOUND=1
            break
        fi
    done

    if [ ${ARCH_FOUND} -eq 0 ]; then
        echo "arch '${ARCH}' is not allowed. Valid archs are: ${VALID_ARCHS}"
        exit 1
    fi
done
