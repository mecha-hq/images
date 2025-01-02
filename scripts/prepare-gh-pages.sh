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
GH_PAGES_DST="dist/gh-pages/${IMAGE_NAME}/${IMAGE_VERSION}"

mkdir -p "${GH_PAGES_DST}"

cp -r ${GH_PAGES_SRC}/sboms/* "${GH_PAGES_DST}"
cp -r ${GH_PAGES_SRC}/renders/* "${GH_PAGES_DST}"
cp -r ${GH_PAGES_SRC}/reports/* "${GH_PAGES_DST}"
