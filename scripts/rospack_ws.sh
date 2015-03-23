#!/bin/bash

CHECK_COMMAND=$1
CHECK_PKG=$2

REPO_ROOT_PACKAGES_NAMES=$(rospack list | grep -E "${REPOS_ROOT}" | cut -d " " -f 1)
REPO_ROOT_PACKAGES_PATHS=$(rospack list | grep -E "${REPOS_ROOT}" | cut -d " " -f 2)
REPO_ROOT_PACKAGES_WORKSPACES=$(rospack list | grep -E "${REPOS_ROOT}" | cut -d " " -f 2 | grep -oP '.*?(?=/src)' | grep -oP "(?<=${REPOS_ROOT}/).*")


# Build dictionary of package -> workspace pairs
declare -A pkg_workspaces
let "i = 1"
while read -r PACKAGE; do
	WORKSPACE=$(echo -en "${REPO_ROOT_PACKAGES_WORKSPACES}" | sed -n "$i"p)
	pkg_workspaces[$PACKAGE]=$WORKSPACE
	echo "Package '$PACKAGE' is in workspace '$WORKSPACE'."
	let "i++"
done <<< "${REPO_ROOT_PACKAGES_NAMES}"


DEPENDENCIES=$(rospack $CHECK_COMMAND $CHECK_PKG)

while read -r DEPENDENCY; do
	echo "$DEPENDENCY (${pkg_workspaces[$DEPENDENCY]})"
done <<< "${DEPENDENCIES}"
