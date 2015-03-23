#!/bin/bash

# This script checks workspaces and creates them if they are not present

function init_workspace {
	WS=$1
	echo -en "non existing, creating... " | colorize YELLOW
	mkdir -p ${WS}/src
	cd ${WS}/src
	catkin_init_workspace > /dev/null 2>&1
	cd ..
	echo "created." | colorize GREEN
}

pushd . > /dev/null 2>&1

source ${ROSE_TOOLS}/scripts/bash_aliases.sh
for WORKSPACE in `get-all-workspace-paths`
do
	echo -en "Checking for existence of workspace '${WORKSPACE}'... " | colorize BLUE
	if [ -d ${WORKSPACE}/src ]; then

		cd ${WORKSPACE}/src > /dev/null 2>&1
		
		# Check if this workspace already has a top-level CMakelists (so it already is a catkin workspace)
		if [ -f "CMakeLists.txt" ]; then
			echo "existing." | colorize GREEN
		else
			init_workspace ${WORKSPACE}
		fi
	else
		init_workspace ${WORKSPACE}
	fi
done

popd . > /dev/null 2>&1
