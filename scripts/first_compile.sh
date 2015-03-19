#!/bin/bash  

pushd . > /dev/null 2>&1

# Assumes a deployment is already sourced

 # Check if we are sudo user
if [ "$(id -u)" == "0" ]; then
    echo -e "Sorry, you should not run this script as root."
    exit 1
fi

echo "Workspaces file: ${WORKSPACES_FILE}" | colorize BLUE
if [ -f ${WORKSPACES_FILE} ]; then
	echo "Will build the following workspaces:" | colorize BLUE
	for WORKSPACE in `get-all-workspace-paths`
	do
		echo " ${WORKSPACE}" | colorize YELLOW
	done
else
	echo "Could not find workspaces file '${WORKSPACES_FILE}'." | colorize RED
	exit 1
fi

# For catkin_make
source ${ROSE_TOOLS}/scripts/setup_ROS.sh

echo -e "\033[0;34mNow getting all repositories. This will take some time, so you can grab some\E[30;33m\e[5m coffee\033[m!" 

source ${ROSE_TOOLS}/scripts/update_rosinstall.sh

# Clone and/or update all git repositories
git-update-all

if [ $? != 0 ]; then
	echo "Getting or updating repos failed. Stopping first compile." | colorize RED
	exit 1
fi

# Make sure all workspaces are available
source ${ROSE_TOOLS}/scripts/update_workspaces.sh

echo -e "\033[0;34mDoing first compile..." 

for ws in `get-all-workspace-paths`
do
	cd $ws

	catkin_make

	if [ $? == 0 ]; then
		echo "$ws has succesfully been built." | colorize GREEN
	else
		echo "$ws failed to built. Stopping first compile." | colorize RED
		exit 1
	fi

	# Overlay workspaces
	source ${ROSE_TOOLS}/scripts/overlay_workspaces.sh

	# Update library path (for Cyton arms libs)
	source ${ROSE_TOOLS}/scripts/update_library_path.sh

done

echo "Done with first compile, resource-ing bash to source workspaces." | colorize GREEN

source ~/.bashrc

popd > /dev/null 2>&1
