#!/bin/bash

set -eux

cd "$(dirname $0)"

# Verify that the git is clean.
test $(git ls-files -m | wc -l) == 0

# Current version
ver=$(cat VERSION)

# Add one.
newver=$(( ${ver} + 1 ))

# New version
echo $newver > VERSION

git add VERSION

git commit -m "Bumped stable to version ${newver}"
git tag "stable-${newver}"
git checkout stable
git merge master
git checkout master
git push

# EOF
