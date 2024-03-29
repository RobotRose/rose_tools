#!/bin/bash

# Setup ROS enviroment, assumes the following enviroment variables are set:
# ROS_VERSION
# ROS_IP
# ROS_MASTER_URI

echo 'Setting up ROS environment...' | colorize BLUE

echo -n 'ROS_VERSION             = ' | colorize YELLOW
echo ${ROS_VERSION}

ROS_ROOT_DIR="/opt/ros/${ROS_VERSION}"
echo -n 'ROS_ROOT_DIR            = ' | colorize YELLOW
echo ${ROS_ROOT_DIR}

echo -n 'ROS_IP                  = ' | colorize YELLOW
echo ${ROS_IP}

echo -n 'ROS_MASTER_URI          = ' | colorize YELLOW
echo ${ROS_MASTER_URI}

echo -n 'ROSCONSOLE_CONFIG_FILE  = ' | colorize YELLOW
echo ${ROSCONSOLE_CONFIG_FILE}

# Set ROSLAUNCH_SSH_UNKNOWN to true
export ROSLAUNCH_SSH_UNKNOWN=1
echo -n "ROSLAUNCH_SSH_UNKNOWN  = " | colorize YELLOW
echo "enabled"

source "${ROS_ROOT_DIR}/setup.bash"


# echo 'Setting up Rose Simulator...'  | colorize BLUE
# export GAZEBO_PLUGIN_PATH=/usr/lib/gazebo-1.9/plugins:~/git/rose2_0/simulator/devel/lib
# echo -n 'GAZEBO_PLUGIN_PATH = '  | colorize YELLOW
# echo $GAZEBO_PLUGIN_PATH

# export GAZEBO_MODEL_PATH=~/git/rose2_0/simulator/src/rose20_description:~/git/rose2_0/simulator/src/rose20_worlds/
# echo -n 'GAZEBO_MODEL_PATH = ' | colorize YELLOW
# echo $GAZEBO_MODEL_PATH

# ROS package path has to be set for rospack to work
export ROS_PACKAGE_PATH=${ROS_PACKAGE_PATH}:${REPOS_ROOT}
echo -n 'ROS_PACKAGE_PATH	= ' | colorize YELLOW
echo ${ROS_PACKAGE_PATH}

# Update library path
source ${ROSE_TOOLS}/scripts/update_library_path.sh

#Overlay workspaces
source ${ROSE_TOOLS}/scripts/overlay_workspaces.sh

# Set rosconsole format
source ${ROSE_TOOLS}/scripts/setup_rosconsole_format.sh
