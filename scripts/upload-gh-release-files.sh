#!/bin/sh

set -e
set -o errexit -o nounset

KIND="${1}"
IMAGE="${2}"
VERSION="${3}"

IMAGE_LC=$(echo "${IMAGE}" | tr '[:upper:]' '[:lower:]')
VERSION_LC=$(echo "${VERSION}" | tr '[:upper:]' '[:lower:]')
REPORTS_DIR="dist/${KIND}/${IMAGE}/${VERSION}/reports/"
TAG="${IMAGE_LC}-${VERSION_LC}"

if [ -z "${REPORTS_DIR}" ]; then
    echo "No reports directory found"
    exit 1
fi

echo "Uploading files to release ${TAG}..."

RELEASE_ID=$(gh api \
    -H "Accept: application/vnd.github+json" \
    /repos/mecha-hq/images/releases/tags/"${TAG}" \
    --jq '.id'
)

for FILE in $(find "${REPORTS_DIR}" -type f); do
    FILENAME=$(basename "${FILE}")

    echo "Uploading ${FILENAME}..."

    curl -sSL \
        -X POST \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Content-Type: $(file --brief --mime-type "${FILE}")" \
        --data-binary @"${FILE}" \
        "https://uploads.github.com/repos/mecha-hq/images/releases/${RELEASE_ID}/assets?name=${FILENAME}&label=${FILENAME}"
done

echo "All files uploaded successfully."
