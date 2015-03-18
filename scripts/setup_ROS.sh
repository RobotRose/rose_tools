#!/bin/bash  

ROOT=$1
IP=$2
MASTER=$3
GITROOT=$4

# Set up bash aliases and ROSE_TOOLS/scripts env variable, assumes this script is in same directory as this script
source $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/setup_bash.sh

export ROS_ROOT=$ROOT
export ROS_IP=$IP
export ROS_MASTER_URI=$MASTER

echo -n 'ROS_ROOT       		= ' | colorize YELLOW
echo $ROS_ROOT

echo -n 'ROS_IP         		= ' | colorize YELLOW
echo $ROS_IP

echo -n 'ROS_MASTER_URI 		= ' | colorize YELLOW
echo $ROS_MASTER_URI

source /opt/ros/hydro/setup.bash

# echo 'Setting up Rose Simulator...'  | colorize BLUE
# export GAZEBO_PLUGIN_PATH=/usr/lib/gazebo-1.9/plugins:~/git/rose2_0/simulator/devel/lib
# echo -n 'GAZEBO_PLUGIN_PATH = '  | colorize YELLOW
# echo $GAZEBO_PLUGIN_PATH

# export GAZEBO_MODEL_PATH=~/git/rose2_0/simulator/src/rose20_description:~/git/rose2_0/simulator/src/rose20_worlds/
# echo -n 'GAZEBO_MODEL_PATH = ' | colorize YELLOW
# echo $GAZEBO_MODEL_PATH

# ROS package path has to be set for rospack to work
export ROS_PACKAGE_PATH=$ROS_PACKAGE_PATH:$GITROOT
echo -n 'ROS_PACKAGE_PATH 	= ' | colorize YELLOW
echo $ROS_PACKAGE_PATH

# User environment variables
ROBOT_FILE=$(readlink -f /usr/bin/robot_file.sh)
if [ -e /usr/bin/robot_file.sh ]
then
    echo -n "Loading environment variables from ${ROBOT_FILE}... " | colorize BLUE
    source /usr/bin/robot_file.sh
    echo "done" | colorize GREEN
else
    echo "No environment variables file ${ROBOT_FILE} found." | colorize RED
fi

echo -n 'LOCATION OF WORKSPACES FILE = ' | colorize YELLOW
echo $WORKSPACES_FILE

echo -n 'ROSCONSOLE_CONFIG_FILE 	= ' | colorize YELLOW
echo $ROSCONSOLE_CONFIG_FILE

echo 'Setting up ROS environment...' | colorize BLUE

# Update library path (for ROS environment)
source $ROSE_TOOLS/scripts/update_library_path.sh

#Overlay workspaces
source $ROSE_TOOLS/scripts/overlay_workspaces.sh

export ROSLAUNCH_SSH_UNKNOWN=1
echo 'Using unkown SSH hosts enabled.' | colorize BLUE

# Update library path (for Cyton arms)
source $ROSE_TOOLS/scripts/update_library_path.sh

# Set rosconsole format
echo "Setting rosconsole format"  | colorize BLUE
export ROSCONSOLE_FORMAT='${time}|${logger}[${severity}]: ${message}' 

echo -n 'Setup git... ' | colorize BLUE
source $ROSE_TOOLS/scripts/setup_git.sh
echo 'done'  | colorize GREEN
echo

#save history after every command
#use 'history -r' to reload history
PROMPT_COMMAND="history -a ; $PROMPT_COMMAND"

echo "Setup ROS done" | colorize GREEN
