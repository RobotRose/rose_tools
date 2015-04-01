#!/bin/bash

# Load environment variables
# Adds scripts folder to PATH
# Loads bash aliases

# Read arguments
DEPLOYMENT_FILE=$1

echo -en "Sourcing deployment " | colorize BLUE
echo "'$(readlink -f ${DEPLOYMENT_FILE})' " | colorize YELLOW

if [ -f ${DEPLOYMENT_FILE} ]; then
	echo -en "Deployment file " | colorize BLUE
	echo "found." | colorize GREEN
else
	echo -en "Deployment file " | colorize BLUE
	echo "non existing." | colorize RED
	return 1
fi	

# Source deployment file
source ${DEPLOYMENT_FILE}

# Set workspace root location
export REPOS_ROOT="${HOME}/${REPOS_LOCATION}"

# Workspaces
export WORKSPACES_FILE=${REPOS_ROOT}/.workspaces

# Location of the rose_config package
export ROSE_CONFIG="${REPOS_ROOT}/deployment/src/rose_config/rose_config"

# Location of the rose_tools package
export ROSE_TOOLS="${REPOS_ROOT}/deployment/src/rose_tools"

# Initialize environment
echo -n "Adding the rose scripts directory to \$PATH... " | colorize BLUE
export PATH="${ROSE_TOOLS}/scripts:$PATH"
echo "done." | colorize GREEN

echo -n 'Enabling bash aliases... ' | colorize BLUE
source ${ROSE_TOOLS}/scripts/bash_aliases.sh
echo "done." | colorize GREEN

# Source installation
source ${ROSE_TOOLS}/scripts/pc_id.sh "" ""
echo -en "Using PC_ID: " | colorize BLUE
echo "${PC_ID}" | colorize YELLOW

export INSTALLATIONS_ROOT="${ROSE_CONFIG}/installations"
export INSTALLATION_DIR="${INSTALLATIONS_ROOT}/${ROBOT_INSTALLATION}"
source "${INSTALLATION_DIR}/${PC_ID}.sh"

# Determine ROS_IP from ROS_INTERFACE
source ${ROSE_TOOLS}/scripts/determine_ros_ip.sh "${ROS_INTERFACE}"

export ROSINSTALL_DIR="${ROSE_CONFIG}/rosinstall/${ROSINSTALL}"
export ROSINSTALL_FILE="${ROSE_CONFIG}/rosinstall/${ROSINSTALL}/.rosinstall"

# Location of the logging configuration files
export LOGGING_CONF_DIR="${ROSE_CONFIG}/logging/${ROBOT_LOGGING}"

# Location of the launch files
export LAUNCH_DIR="${ROSE_CONFIG}/launch_files/${ROBOT_LAUNCH}"

# Location of the robot parameters
export PARAM_DIR="${ROSE_CONFIG}/configurations/${ROBOT_CONFIG}"

# Source the location
export LOCATIONS_ROOT="${ROSE_CONFIG}/locations"
export LOCATION_DIR="${ROSE_CONFIG}/locations/${ROBOT_LOCATION}"
source "${LOCATION_DIR}/location.sh"

echo -en "Deployment " | colorize BLUE
echo -en "'$(readlink -f ${DEPLOYMENT_FILE})' " | colorize YELLOW
echo "sourced." | colorize GREEN
