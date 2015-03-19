#!/bin/bash  

pushd . 

ROBOT_FILE=$1

if [[ "$ROBOT_FILE" == "" ]]; then
	echo "First parameter should specify the robot file."
	exit 1
fi

 # Check if we are sudo user
if [ "$(id -u)" == "0" ]; then
    echo -e "Sorry, you should not run this script as root."
    exit 1
fi

# Setup the vars in robot_file.sh by sourcing the symlinked file in /usr/bin.
# This file is installed by running the first_install.sh script
ROBOT_FILE=$(readlink /usr/bin/robot_file.sh)
echo "ROBOT_FILE = $ROBOT_FILE"
if [ -f $ROBOT_FILE ]; then
	source $ROBOT_FILE
else
	echo "Could not find link target of /usr/bin/robot_file.sh -> ${ROBOT_FILE}. Did you run first_install.sh on this PC?" 
	read -p "Press CTRL+C to stop script or Enter to exit"
	exit 1
fi

# Set up bash aliases and ROSE_TOOLS/scripts env variable, assumes this script is in same directory as this script
source $ROSE_TOOLS/scripts/setup_bash.sh

# Filter the rose config location from the developers config file
#ROSE_CONFIG=${ROBOT_FILE%/rose_config/*}/rose_config

echo "Sourcing robot file: $ROBOT_FILE" | colorize BLUE
source $ROBOT_FILE

echo "Workspaces file: $WORKSPACES_FILE" | colorize BLUE
if [ -f $WORKSPACES_FILE ]; then
	echo "Will build the following workspaces:" | colorize BLUE
	for ws in `get-all-ws-names`
	do
		echo " $ws" | colorize YELLOW
	done
else
	echo "Could not find workspaces file." | colorize RED
	exit 1
fi

# For catkin_make
source $ROSE_TOOLS/scripts/setup_ROS.sh

echo -e "\033[0;34mNow getting all repositories. This will take some time, so you can grab some\E[30;33m\e[5m coffee!\033[m" 

source $ROSE_TOOLS/scripts/update_rosinstall.sh

# Clone and/or update all git repositories
git-update-all

if [ $? != 0 ]; then
	echo "Getting or updating repos failed. Stopping first compile." | colorize RED
	exit 1
fi

# Make sure all workspaces are available
source $ROSE_TOOLS/scripts/update_workspaces.sh

echo -e "\033[0;34mDoing first compile..." 

for ws in `get-all-ws-paths`
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
	source $ROSE_TOOLS/scripts/overlay_workspaces.sh

	# Update library path (for Cyton arms libs)
	source $ROSE_TOOLS/scripts/update_library_path.sh

done

echo "Done with first compile, resource-ing bash to source workspaces." | colorize GREEN

source ~/.bashrc

popd
