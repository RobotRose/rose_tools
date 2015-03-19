#!/bin/bash

# Setup ROS enviroment, assumes the following enviroment variables are set:
# ROS_ROOT
# ROS_IP
# ROS_MASTER_URI

echo 'Setting up ROS environment...' | colorize BLUE

echo -n 'ROS_ROOT       		= ' | colorize YELLOW
echo ${ROS_ROOT}

echo -n 'ROS_IP         		= ' | colorize YELLOW
echo ${ROS_IP}

echo -n 'ROS_MASTER_URI 		= ' | colorize YELLOW
echo ${ROS_MASTER_URI}

source "${ROS_ROOT}/setup.bash"

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
# source ${ROSE_TOOLS}/scripts/update_library_path.sh
export LD_LIBRARY_PATH="${ROS_ROOT}/lib/:/usr/lib/gazebo-1.9/plugins" #:~/git/rose2_0/simulator/devel/lib
echo -n 'LD_LIBRARY_PATH		= ' | colorize YELLOW
echo ${LD_LIBRARY_PATH}

#Overlay workspaces
source ${ROSE_TOOLS}/scripts/overlay_workspaces.sh

# Set rosconsole format
echo "Setting rosconsole format"  | colorize BLUE
export ROSCONSOLE_FORMAT='${time}|${logger}[${severity}]: ${message}' 
