#!/bin/sh

set -e
set -o errexit -o nounset

IMAGE_KIND="${1}"
IMAGE_NAME="${2}"
IMAGE_VERSION="${3}"

if [ -z "${IMAGE_KIND}" ]; then echo "Argument 1 (IMAGE_KIND) is required"; exit 1; fi
if [ -z "${IMAGE_NAME}" ]; then echo "Argument 1 (IMAGE_NAME) is required"; exit 1; fi
if [ -z "${IMAGE_VERSION}" ]; then echo "Argument 1 (IMAGE_VERSION) is required"; exit 1; fi

GH_PAGES_SRC="dist/${IMAGE_KIND}/${IMAGE_NAME}/${IMAGE_VERSION}"
GH_PAGES_DST="dist/pages/${IMAGE_NAME}/${IMAGE_VERSION}"

mkdir -p "${GH_PAGES_DST}"

# Copy the reports
cp -r ${GH_PAGES_SRC}/reports/* "${GH_PAGES_DST}"

# Copy the SBOMs
cp ${GH_PAGES_SRC}/sboms/sbom-index.spdx.json "${GH_PAGES_DST}"
cp ${GH_PAGES_SRC}/sboms/sbom-aarch64.spdx.json "${GH_PAGES_DST}/arm64"
cp ${GH_PAGES_SRC}/sboms/sbom-x86_64.spdx.json "${GH_PAGES_DST}/amd64"

# Create the tool-version-arm64 index page
cat >"${GH_PAGES_DST}/arm64/_index.md" <<-EOF
+++
title = 'arm64'
layout = 'tool-version-arch'
showDate = false
+++
EOF

# Create the tool-version-amd64 index page
cat >"${GH_PAGES_DST}/amd64/_index.md" <<-EOF
+++
title = 'amd64'
layout = 'tool-version-arch'
showDate = false
+++
EOF

# Create the tool-version index page
cat >"${GH_PAGES_DST}/_index.md" <<-EOF
+++
title = '${IMAGE_VERSION}'
showDate = false
+++
EOF

# Create the tool index page
cat >"dist/pages/${IMAGE_NAME}/_index.md" <<-EOF
+++
title = '${IMAGE_NAME}'
description = 'All the versions of ${IMAGE_NAME} at your disposal'
showDate = false
+++
EOF
