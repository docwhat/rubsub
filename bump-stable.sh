#!/bin/bash

set -eu

cd "$(dirname $0)"

# Verify that there is something to do.
if [[ $(git log master..stable | wc -l) == 0 ]]; then
    echo There are no changes to push into stable.
    exit 1
fi

# Verify that the git is clean.
if [[ $(git ls-files -m | wc -l) != 0 ]];then
    echo "Your git repo isn't clean."
    exit 2
fi

exit 10

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
git push --tags

# EOF
