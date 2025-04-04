#!/bin/sh

set -e
set -o errexit -o nounset

IMAGE_NAME="${1}"

if [ -z "${IMAGE_NAME}" ]; then echo "Argument 1 (IMAGE_NAME) is required"; exit 1; fi

find . -maxdepth 2 -name "${IMAGE_NAME}" -type d | grep -E 'tools|collections' | cut -d '/' -f 2
