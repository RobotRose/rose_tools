#!/bin/bash

WORKSPACES_FILE="${REPOS_ROOT}/.workspaces"
WORKSPACEs_BUILD_ORDER_FILE="${REPOS_ROOT}/.workspaces_build_order"

if [ "$REPOS_ROOT" == "" ]; then
	echo "Enviroment variable REPOS_ROOT is not defined." | colorize RED
	exit 1
else
	echo -n "Determining workspaces build order in repository root: " | colorize BLUE
	echo "$REPOS_ROOT" | colorize YELLOW
fi

ROS_PACKAGE_PATH_TEMP=$ROS_PACKAGE_PATH
while read -r WORKSPACE_NAME; do
	ROS_PACKAGE_PATH="${REPOS_ROOT}/${WORKSPACE_NAME}/src:${ROS_PACKAGE_PATH}"
done < $WORKSPACES_FILE

echo -n "Setting ROS_PACKAGE_PATH to: " | colorize BLUE
echo "$ROS_PACKAGE_PATH" | colorize YELLOW

# Get packages in repository root
REPO_ROOT_PACKAGES_NAMES=$(rospack list | grep -E "${REPOS_ROOT}" | cut -d " " -f 1)
REPO_ROOT_PACKAGES_PATHS=$(rospack list | grep -E "${REPOS_ROOT}" | cut -d " " -f 2)
REPO_ROOT_PACKAGES_WORKSPACES=$(rospack list | grep -E "${REPOS_ROOT}" | cut -d " " -f 2 | grep -oP '.*?(?=/src)' | grep -oP "(?<=${REPOS_ROOT}/).*")

echo -en "Found workspaces: \n" | colorize BLUE
echo "$(echo -e "$REPO_ROOT_PACKAGES_WORKSPACES" | sort -u)" | colorize CYAN

declare -A pkg_workspaces
	
# Build dictionary of package -> workspace pairs
let "i = 1"
while read -r PACKAGE; do
	WORKSPACE=$(echo -en "${REPO_ROOT_PACKAGES_WORKSPACES}" | sed -n "$i"p)
	pkg_workspaces[$PACKAGE]=$WORKSPACE
	# echo "Package '$PACKAGE' is in workspace '$WORKSPACE'."
	let "i++"
done <<< "${REPO_ROOT_PACKAGES_NAMES}"



declare -A pkg_dependencies
declare -A ws_dependencies
declare -A ws_ws_pkg_dependencies

# Build dictionary of package X -> Depends on packages list
ERROR_TEMP_FILE=$(mktemp)
while read -r PACKAGE; do
	WORKSPACE=${pkg_workspaces[$PACKAGE]}
	DEPENDENCIES=$(rospack depends ${PACKAGE} 2> $ERROR_TEMP_FILE )
	ERROR="$(< $ERROR_TEMP_FILE)"
	# echo "${DEPENDENCIES}"
	

	# Check if there where any dependencies returned, otherwise skip
	NR_OF_DEPENDENCIES=$(echo -en "${DEPENDENCIES}" | wc -l)
	if [ "${NR_OF_DEPENDENCIES}" == "0" ]; then
		echo "No dependencies for '${PACKAGE} (${WORKSPACE})'" | colorize YELLOW
	else
		echo "'${PACKAGE} (${WORKSPACE})' has ${NR_OF_DEPENDENCIES} global dependencies." | colorize BLUE
		# Check for each dependency in DEPENDENCIES whether it is in REPO_ROOT_PACKAGES_NAMES, thus check if we assigned a workspace to it in pkg_workspaces.
		# We want to skip dependencies outside the workspaces.
		while read -r DEPENDENCY; do
			
			if [ "${pkg_workspaces[$DEPENDENCY]}" != "" ]; then
				pkg_dependencies[$PACKAGE]+="${DEPENDENCY}\n"
				DEPENDENCY_WORKSPACE="${pkg_workspaces[$DEPENDENCY]}"
				if [ "$WORKSPACE" != "$DEPENDENCY_WORKSPACE" ]; then
					ws_dependencies[$WORKSPACE]+="${DEPENDENCY_WORKSPACE}\n"

					if [ "${ws_ws_pkg_dependencies[$WORKSPACE -> $DEPENDENCY_WORKSPACE]}" == "" ]; then
						WS_WS_DEP=$(echo -en "${PACKAGE} -> ${DEPENDENCY} (${DEPENDENCY_WORKSPACE})" | sort -u | uniq -u)
					else
						WS_WS_DEP=$(echo -en "${ws_ws_pkg_dependencies[$WORKSPACE -> $DEPENDENCY_WORKSPACE]}\n${PACKAGE}->${DEPENDENCY}(${DEPENDENCY_WORKSPACE})" | sort -u | uniq -u)
					fi

					ws_ws_pkg_dependencies["$WORKSPACE -> $DEPENDENCY_WORKSPACE"]="$WS_WS_DEP"
					echo -en " Dependency "
					echo -en "$WORKSPACE -> $DEPENDENCY_WORKSPACE " | colorize CYAN
					echo -en "due to dependency on: "
					echo -en "$DEPENDENCY\n" | colorize CYAN
				fi
			fi
			
		done <<< "${DEPENDENCIES}"
	fi

	# Check for error
	if [ "$ERROR" != "" ]; then
		echo -en "${ERROR}\n" | colorize RED
	fi

done <<< "${REPO_ROOT_PACKAGES_NAMES}"

# Resetting ros package path
export ROS_PACKAGE_PATH=$ROS_PACKAGE_PATH_TEMP
echo -n "Re-setting ROS_PACKAGE_PATH to: " | colorize BLUE
echo "$ROS_PACKAGE_PATH" | colorize YELLOW

# Show workspace dependencies
echo "Workspace dependencies: " | colorize BLUE
WORKSPACE_GRAPH_EDGES=""
while read -r WORKSPACE; do
	while read -r DEPEND_ON_WORKSPACE; do
		if [ "$WORKSPACE" != "$DEPEND_ON_WORKSPACE" ]; then
			WORKSPACE_GRAPH_EDGE="$WORKSPACE,$DEPEND_ON_WORKSPACE"
			
			if [ "$WORKSPACE_GRAPH_EDGES" == "" ]; then
				WORKSPACE_GRAPH_EDGES="$(echo -en "$WORKSPACE_GRAPH_EDGE")"
			else
				WORKSPACE_GRAPH_EDGES="$(echo -en "$WORKSPACE_GRAPH_EDGES\n$WORKSPACE_GRAPH_EDGE")"
			fi

			if [ "$DEPEND_ON_WORKSPACE" != "" ]; then
				echo "$WORKSPACE -> $DEPEND_ON_WORKSPACE" | colorize CYAN
				if [ $(echo "${ws_ws_pkg_dependencies[$WORKSPACE -> $DEPEND_ON_WORKSPACE]}" | wc -l) != "0" ]; then
					PKG_LIST=$(echo -en ${ws_ws_pkg_dependencies[$WORKSPACE -> $DEPEND_ON_WORKSPACE]} | tr ' ' $'\n')
					# PKG_LIST=${PKG_LIST// /'/n'}

					echo -e "${PKG_LIST}"
				fi
			fi
		fi
	done <<< "$(echo -en "${ws_dependencies[$WORKSPACE]}" | sort -u | uniq -u)"
done <<< "$(echo -en "${REPO_ROOT_PACKAGES_WORKSPACES}" | sort -u | uniq -u)"	

# Determine correct build order:
WORKSPACE_BUILD_ORDER=""
let "order = 1"
while true; do
	FOUND_BUILDABLE_NODE="false"
	while read -r EDGE; do
		# Find workspaces with only incoming edges
		LEFT_NODE=$(echo "$EDGE" | cut -d , -f 1)
		RIGHT_NODE=$(echo "$EDGE" | cut -d , -f 2)

		# Check for empty lines
		if [ "$LEFT_NODE" == "" ]; then
			continue
		fi

		# echo " Checking $LEFT_NODE -> $RIGHT_NODE"

		if [ "$RIGHT_NODE" == "" ]; then
			echo -en "Build: "
			echo "$LEFT_NODE" | colorize GREEN
			BUILD_ORDER="$BUILD_ORDER\n$order:$LEFT_NODE"
			BUILD_ORDER_PATH="$BUILD_ORDER_PATH\n$order:$LEFT_NODE:${REPOS_ROOT}/${LEFT_NODE}"
			
			# Remove only dependencies where LEFT_NODE appears on the right, if there are any
			if [ "$(echo -en "$WORKSPACE_GRAPH_EDGES" | grep ",$LEFT_NODE" | wc -l)" -gt "0" ]; then
				REMOVE_RN=$(echo -e "${WORKSPACE_GRAPH_EDGES}" | grep ",$LEFT_NODE")
				REMOVE_RN_LNODES=$(echo -en "$REMOVE_RN" | cut -d , -f 1)
				
				# echo "Removing edge(s) with '$LEFT_NODE' appears on right."
				while read -r REMOVE_LN; do
					# Check if the RN appears as left node and has more than one outgoing dependency?
					NR_OUTGOING=$(echo -e "$WORKSPACE_GRAPH_EDGES" | grep "$REMOVE_LN," | wc -l)
					if [ "$NR_OUTGOING" -gt "1" ]; then
						# Just remove the line in $REMOVE_LN,$LN
						WORKSPACE_GRAPH_EDGES="$(echo -e "${WORKSPACE_GRAPH_EDGES}" | grep -v "$REMOVE_LN,$LEFT_NODE")"
						# echo "Removing $REMOVE_LN,$LEFT_NODE"
					else
						# Remove but reintroduce node without outgoing edges
						WORKSPACE_GRAPH_EDGES="$(echo -e "${WORKSPACE_GRAPH_EDGES}" | grep -v "$REMOVE_LN,$LEFT_NODE")"
						WORKSPACE_GRAPH_EDGES="$REMOVE_LN,\n$WORKSPACE_GRAPH_EDGES"
						# echo "Changing $REMOVE_LN,$LEFT_NODE into $REMOVE_LN,"
					fi
				done <<< "${REMOVE_RN_LNODES}"
			fi

			# Filter out all lines where LEFT_NODE still appears on the left
			# This removes nodes with zero outgoing dependencies
			WORKSPACE_GRAPH_EDGES=$(echo -e "$WORKSPACE_GRAPH_EDGES" | grep -v "$LEFT_NODE," )
			
			# Remember that we converged
			FOUND_BUILDABLE_NODE="true"

		fi
	done <<< "$WORKSPACE_GRAPH_EDGES"

	let "order++"

	if [ "$WORKSPACE_GRAPH_EDGES" == "" ]; then
		echo "Complete build order constructed, writing to ${WORKSPACEs_BUILD_ORDER_FILE}" | colorize BLUE
		echo -e "$BUILD_ORDER" | colorize GREEN
		echo -en "$BUILD_ORDER_PATH" > $WORKSPACEs_BUILD_ORDER_FILE
		break;
	fi

	echo "Workspace graph edges: "
	echo -e "$WORKSPACE_GRAPH_EDGES" | colorize CYAN

	if [ "$FOUND_BUILDABLE_NODE" == "false" ]; then
		echo "Circular dependency detected." | colorize RED
		exit 1
	fi
done
