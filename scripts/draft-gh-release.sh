#!/bin/sh

set -e
set -o errexit -o nounset

KIND="${1}"
IMAGE="${2}"
VERSION="${3}"

IMAGE_LC=$(echo "${IMAGE}" | tr '[:upper:]' '[:lower:]')
VERSION_LC=$(echo "${VERSION}" | tr '[:upper:]' '[:lower:]')

if ! gh release view ${IMAGE_LC}-${VERSION_LC} &>/dev/null; then
    gh release create \
        --generate-notes \
        --draft=true \
        --title="${IMAGE} ${VERSION}" \
        "${IMAGE_LC}-${VERSION_LC}"
fi
