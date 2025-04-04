#!/bin/sh

set -e
set -o errexit -o nounset

IMAGE_NAME="${1}"

if [ -z "${IMAGE_NAME}" ]; then echo "Argument 1 (IMAGE_NAME) is required"; exit 1; fi

grep 'version' tools/${IMAGE_NAME}/melange.yaml | head -n 1 | sed 's/.*version: *//' | sed 's/"//g'
