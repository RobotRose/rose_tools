#!/bin/bash

# This script checks workspaces and makes them if they are not present

pushd .

source $ROSE_TOOLS/scripts/setup_bash.sh

for ws in `get-all-ws-paths`
do
	if [ ! -d $ws/src ]; then
		echo "Path $ws/src does not exist, creating it..." | colorize BLUE
		mkdir -p $ws/src
	fi

	cd $ws/src

	# Check if this workspace has a top-level CMakelists (so it is a catkin workspace)
	echo "Checking $ws/src/CMakeList.txt" | colorize BLUE
	if [ -f "CMakeLists.txt" ]; then
		echo "Workspace found at $ws" | colorize GREEN
	else
		echo "Creating workspace at $ws..." | colorize YELLOW
		cd $ws/src
		catkin_init_workspace
		cd ..
	fi
done

popd .