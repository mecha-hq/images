#!/bin/sh

set -e
set -o errexit -o nounset

find ytt/.github/workflows/*.yml -maxdepth 1 -type f -name "*.yml" ! -name "*.lib.yml" | while read -r src; do
    dst=$(echo "${src}" | sed 's/ytt\///g' | sed 's/.yml/.yaml/g')

    ytt \
        --file "ytt/.github/workflows/fragments.lib.yml" \
        --file "${src}" | \
        yq --indent=2 | \
        sed 's/^\"on\"\:$/on:/' | \
        sed 's/^  workflow_dispatch: null$/  workflow_dispatch:/' | \
        sed 's/^  pull_request: null$/  pull_request:/' | \
        sed '1i # yaml-language-server: $schema=https://json.schemastore.org/github-workflow\n' \
        > "${dst}"
done
