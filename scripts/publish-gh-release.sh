#!/bin/sh

set -e
set -o errexit -o nounset

IMAGE="${1}"
VERSION="${2}"

IMAGE_LC=$(echo "${IMAGE}" | tr '[:upper:]' '[:lower:]')
VERSION_LC=$(echo "${VERSION}" | tr '[:upper:]' '[:lower:]')

gh release edit --draft=false "${IMAGE_LC}-${VERSION_LC}"
