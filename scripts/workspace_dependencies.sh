#!/bin/bash

# Get packages in repository root
REPO_ROOT_PACKAGES_NAMES=$(rospack list | grep -E "${REPOS_ROOT}" | cut -d " " -f 1)
REPO_ROOT_PACKAGES_PATHS=$(rospack list | grep -E "${REPOS_ROOT}" | cut -d " " -f 2)
REPO_ROOT_PACKAGES_WORKSPACES=$(rospack list | grep -E "${REPOS_ROOT}" | cut -d " " -f 2 | grep -oP '.*?(?=/src)' | grep -oP "(?<=${REPOS_ROOT}/).*")

echo -en "${REPO_ROOT_PACKAGES_NAMES}"
echo -en "${REPO_ROOT_PACKAGES_PATHS}"
echo -en "${REPO_ROOT_PACKAGES_WORKSPACES}"

get() {
    mapName=$1; key=$2

    map=${!mapName}
    value="$(echo $map |sed -e "s/.*--${key}=\([^ ]*\).*/\1/" -e 's/:SP:/ /g' )"
}

declare -A pkg_dependencies

# Determine dependencies
while read -r NAME_A; do
	while read -r NAME_B; do
		echo "$NAME_A -> $NAME_B"
		DEP_CHAINS=rospack deps-why --target=${NAME_A} ${NAME_B}
		echo "${DEP_CHAINS}"
		pkg_dependencies[$NAME_A]+=$DEP_CHAINS
	done <<< "${REPO_ROOT_PACKAGES_NAMES}"

	echo ${pkg_dependencies[$NAME_A]}
	echo ""
done <<< "${REPO_ROOT_PACKAGES_NAMES}"

