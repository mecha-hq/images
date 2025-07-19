#!/bin/sh

set -e
set -o errexit -o nounset

KIND="${1}"
IMAGE="${2}"
VERSION="${3}"

IMAGE_LC=$(echo "${IMAGE}" | tr '[:upper:]' '[:lower:]')
VERSION_LC=$(echo "${VERSION}" | tr '[:upper:]' '[:lower:]')
REPORTS_DIR="dist/${KIND}/${IMAGE}/${VERSION}/reports/"

if [ -z "${REPORTS_DIR}" ]; then
    echo "No reports directory found"
    exit 1
fi

REPORTS_FILES=$(find "${REPORTS_DIR}" -type f -printf "%p " 2>/dev/null)

echo "Uploading files to release ${IMAGE_LC}-${VERSION_LC}..."

gh release upload "${IMAGE_LC}-${VERSION_LC}" ${REPORTS_FILES} \
    --repo mecha-hq/images \
    --clobber
