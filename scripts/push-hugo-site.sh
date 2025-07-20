#!/bin/sh

set -e
set -o errexit -o nounset

SUBJECT=${1:-"the static site"}
BRANCH=${2:-"main"}

git config --global user.email "github-actions[bot]@users.noreply.github.com"
git config --global user.name "GitHub Actions"

# Push the contents to the images-pages-content repository
cd pages/content

git add .

# Only commit and push if there are staged changes
if ! git diff --cached --quiet; then
    git remote set-url origin "https://${CI_TOKEN}@github.com/mecha-hq/images-pages-content.git"

    git commit -m "Update content for ${SUBJECT}"
    git push origin "HEAD:${BRANCH}"
else
    echo "No content changes to commit."
fi

# Return to parent repo and commit the updated submodule pointer
cd ../..

git add pages/content

# Only commit and push if there are staged changes
if ! git diff --cached --quiet; then
  git commit -m "Update submodule reference for ${SUBJECT}"
  git push origin "HEAD:${BRANCH}"
else
  echo "No submodule reference change to commit."
fi
