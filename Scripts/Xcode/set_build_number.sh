#!/usr/bin/env bash

# NOTE: Executed by Xcode in Run script phase

set -o errexit
set -o nounset

hash git 2>/dev/null || { echo >&2 "Git required, not installed.  Aborting build number update script."; exit 0; }
number_of_commits=$(git rev-list HEAD --count)
version_from_tag=$(git describe --tags --always --abbrev=0)
current_commit_shorthash=$(git rev-parse --short HEAD)

plist="$BUILT_PRODUCTS_DIR/$INFOPLIST_PATH"

/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $number_of_commits" "$plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${version_from_tag#*v}" "$plist"
/usr/libexec/PlistBuddy -c "Set :GitShortHash $current_commit_shorthash" "$plist"
