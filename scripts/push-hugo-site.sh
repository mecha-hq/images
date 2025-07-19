#!/bin/sh

set -e
set -o errexit -o nounset

IMAGE_NAME=${1}
IMAGE_VERSION=${2}

if [ -z "${IMAGE_NAME}" ]; then echo "Argument 1 (IMAGE_NAME) is required"; exit 1; fi
if [ -z "${IMAGE_VERSION}" ]; then echo "Argument 2 (IMAGE_VERSION) is required"; exit 1; fi

git config --global user.email "github-actions[bot]@users.noreply.github.com"
git config --global user.name "GitHub Actions"

# Push the contents to the images-pages-content repository
cd pages/content

git add .

# Only commit and push if there are staged changes
if ! git diff --cached --quiet; then
    git commit -m "Update content for ${IMAGE_NAME}:${IMAGE_VERSION}"
    git push
else
    echo "No content changes to commit."
fi

# Return to parent repo and commit the updated submodule pointer
cd ../..

git add pages/content

# Only commit and push if there are staged changes
if ! git diff --cached --quiet; then
  git commit -m "Update submodule reference for ${IMAGE_NAME}:${IMAGE_VERSION}"
  git push
else
  echo "No submodule reference change to commit."
fi
