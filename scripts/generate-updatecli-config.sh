#!/bin/sh

set -e
set -o errexit -o nounset

find ytt/.github/workflows/*.yml -maxdepth 1 -type f -name "*.yml" ! -name "*.lib.yml" | while read -r src; do
    dst=$(echo "${src}" | sed 's/ytt\///g' | sed 's/.yml/.yaml/g')

    ytt \
        -f "ytt/.github/workflows/fragments.lib.yml" \
        -f "${src}" | \
        yq --indent=2 | \
        sed 's/^\"on\"\:$/on:/' | \
        sed 's/^  workflow_dispatch: null$/  workflow_dispatch:/' > "${dst}"
done

find ytt/updatecli/updatecli.d/*.yml -maxdepth 1 -type f -name "*.yml" ! -name "*.lib.yml" | while read -r src; do
    dst=$(echo "${src}" | sed 's/ytt\///g' | sed 's/.yml/.yaml/g')

    ytt \
        -f "ytt/updatecli/updatecli.d/fragments.lib.yml" \
        -f "${src}" | \
        yq --indent=2 > "${dst}"
done
