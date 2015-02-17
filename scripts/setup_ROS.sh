#!/bin/bash  

ROOT=$1
IP=$2
MASTER=$3
GITROOT=$4

# Set up bash aliases and ROSE_SCRIPTS env variable, assumes this script is in same directory as this script
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

#User prefs]
if [ -e $ROBOT_FILE ]
then
    echo -n "Loading environment variables from $ROBOT_FILE... " | colorize BLUE
    source $ROBOT_FILE
    echo "done" | colorize GREEN
else
    echo "No environment variables for $ROBOT_NAME" | colorize RED
fi

echo -n 'LOCATION OF WORKSPACES FILE = ' | colorize YELLOW
echo $WORKSPACES_FILE

echo -n 'ROSCONSOLE_CONFIG_FILE 	= ' | colorize YELLOW
echo $ROSCONSOLE_CONFIG_FILE

export LD_LIBRARY_PATH=/opt/ros/hydro/lib/:/usr/lib/gazebo-1.9/plugins #:~/git/rose2_0/simulator/devel/lib
echo -n 'LD_LIBRARY_PATH = ' | colorize YELLOW
echo $LD_LIBRARY_PATH

echo 'Setting up ROS environment...' | colorize BLUE

#Overlay workspaces
source $ROSE_SCRIPTS/overlay_workspaces.sh

export ROSLAUNCH_SSH_UNKNOWN=1
echo 'Using unkown SSH hosts enabled.' | colorize BLUE

echo 'Setting up Cyton arms...'  | colorize BLUE
export EC_LOCATION=`rospack find rose_third_party`/robai
echo -n 'EC_LOCATION = ' | colorize YELLOW
echo $EC_LOCATION

# Adding Robai lib/bin to LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$EC_LOCATION/bin:$EC_LOCATION/lib
echo -n 'LD_LIBRARY_PATH = ' | colorize YELLOW
echo $LD_LIBRARY_PATH

# Set rosconsole format
echo "Setting rosconsole format"  | colorize BLUE
export ROSCONSOLE_FORMAT='${time}|${logger}[${severity}]: ${message}' 

echo -n 'Setup git... ' | colorize BLUE
source $ROSE_SCRIPTS/setup_git.sh
echo 'done'  | colorize GREEN
echo

#save history after every command
#use 'history -r' to reload history
PROMPT_COMMAND="history -a ; $PROMPT_COMMAND"

echo "Setup ROS done" | colorize GREEN
