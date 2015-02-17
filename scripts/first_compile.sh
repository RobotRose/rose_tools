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

# Setup the rose scripts folder by running the set_rose_scripts_folder.sh in /usr/bin.
# This file is installed by running the first_install.sh script
source set_rose_scripts_folder.sh

if [ $? != 0 ]; then
	echo "Could not find the set_rose_scripts_folder script. Did you run first_install.sh on this PC?"
	exit 1
fi

# Set up bash aliases and ROSE_SCRIPTS env variable, assumes this script is in same directory as this script
source $ROSE_SCRIPTS/setup_bash.sh

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
source $ROSE_SCRIPTS/setup_ROS.sh

echo "Setting the rosinstall file" | colorize BLUE
wstool init $ROSINSTALL_ROOT $ROSE_CONFIG/rosinstall/.rosinstall

echo "Running git-update-all" | colorize BLUE
git-update-all

echo -en "\033[0;34mNow doing first compile. This will take some time, so you can grab some\E[30;33m\e[5m coffee!\033[m" 
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
	source $ROSE_SCRIPTS/overlay_workspaces.sh

done

echo "Done with first compile, resource-ing bash to source workspaces." | colorize GREEN

source ~/.bashrc

popd
