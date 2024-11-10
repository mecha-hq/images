#!/bin/sh

set -e
set -o errexit -o nounset

NAME=${1}
NAME_FOUND=0
VALID_NAMES=$(find collections tools -type d | cut -d '/' -f 2 | xargs)

for VALID_NAME in ${VALID_NAMES}; do
    if [ "${NAME}" = "${VALID_NAME}" ]; then
        NAME_FOUND=1
        break
    fi
done

if [ ${NAME_FOUND} -eq 0 ]; then
    echo "name '${NAME}' is not allowed. Valid names are: ${VALID_NAMES}"
    exit 1
fi
