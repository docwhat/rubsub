#!/bin/bash

set -eu

cd "$(dirname $0)"

# Verify we're on the right branches.
local=$(git rev-parse --symbolic-full-name HEAD | cut -f3 -d/)
remote=$(git config branch.${local}.remote || :)
merge=$(git config branch.${local}.merge || :)
merge=${merge/#refs\/heads\//}

if [[ "${merge}" != "master" ]]; then
    echo "You're on the wrong branch: ${local} mirrors ${remote}/${merge}"
    exit 3
fi

# Verify that there is something to do.
if [[ $(git log stable.. | wc -l) == 0 ]]; then
    echo "There are no changes to push into stable."
    exit 1
fi

# Verify that the git is clean.
if [[ $(git ls-files -m | wc -l) != 0 ]];then
    echo "Your git repo isn't clean."
    exit 2
fi

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
