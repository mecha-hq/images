#!/bin/sh

set -e
set -o errexit -o nounset

BASE_URL="${1}"

if [ -z "${BASE_URL}" ]; then echo "Argument 1 (BASE_URL) is required"; exit 1; fi

hugo \
    --gc \
    --minify \
    --baseURL "${BASE_URL}" \
    --source pages/
