#!/bin/bash

# Load environment variables
# Adds scripts folder to PATH
# Loads bash aliases

# Read arguments
DEPLOYMENT_FILE=$1

if [ -f ${DEPLOYMENT_FILE} ]; then
	echo "Deployment ${DEPLOYMENT_FILE} found." | colorize BLUE
else
	echo "Deployment ${DEPLOYMENT_FILE} is non existing." | colorize RED
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
echo -n "Adding the rose scripts dir to the PATH... " | colorize BLUE
export PATH="${ROSE_TOOLS}/scripts:$PATH"
echo 'done' | colorize GREEN

echo -n 'Enabling bash aliases... ' | colorize BLUE
source ${ROSE_TOOLS}/scripts/bash_aliases.sh
echo 'done' | colorize GREEN

# Source installation
source "${ROSE_CONFIG}/installations/${ROBOT_INSTALLATION}/pc1.sh"

export ROSINSTALL_FILE="${ROSE_CONFIG}/rosinstall/${ROSINSTALL}/.rosinstall"

echo "Deployment '${DEPLOYMENT_ID}' sourced." | colorize GREEN
