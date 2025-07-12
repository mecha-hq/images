#!/bin/sh

set -e
set -o errexit -o nounset

find ytt/updatecli/updatecli.d/**/*.yml -type f -name "*.yml" ! -name "*.lib.yml" | while read -r src; do
    dst=$(echo "${src}" | sed 's/ytt\///g' | sed 's/.yml/.yaml/g')

    mkdir -p "$(dirname ${dst})"

    ytt \
        -f "ytt/updatecli/updatecli.d/fragments.lib.yml" \
        -f "${src}" | \
        yq --indent=2 > "${dst}"
done
