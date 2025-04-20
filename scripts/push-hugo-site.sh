#!/bin/sh

set -e
set -o errexit -o nounset

IMAGE_NAME=${1}
IMAGE_VERSION=${2}

if [ -z "${IMAGE_NAME}" ]; then echo "Argument 1 (IMAGE_NAME) is required"; exit 1; fi
if [ -z "${IMAGE_VERSION}" ]; then echo "Argument 2 (IMAGE_VERSION) is required"; exit 1; fi

git config --global user.email "github-actions[bot]@users.noreply.github.com"
git config --global user.name "GitHub Actions"
git add pages/content

# Only commit and push if there are staged changes
if ! git diff --cached --quiet; then
  git commit -m "Update GitHub Pages content with ${IMAGE_NAME}:${IMAGE_VERSION} data."
  git push
else
  echo "No changes to commit."
fi
