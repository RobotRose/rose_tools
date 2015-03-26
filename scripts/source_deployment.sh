#!/bin/bash

# Load environment variables
# Adds scripts folder to PATH
# Loads bash aliases

# Read arguments
DEPLOYMENT_FILE=$1

echo -en "Sourcing deployment " | colorize BLUE
echo "'${DEPLOYMENT_FILE}' " | colorize YELLOW

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
source "${ROSE_CONFIG}/installations/${ROBOT_INSTALLATION}/${PC_ID}.sh"

export ROSINSTALL_DIR="${ROSE_CONFIG}/rosinstall/${ROSINSTALL}"
export ROSINSTALL_FILE="${ROSE_CONFIG}/rosinstall/${ROSINSTALL}/.rosinstall"

echo -en "Deployment " | colorize BLUE
echo -en "'${DEPLOYMENT_ID}' " | colorize YELLOW
echo "sourced." | colorize GREEN
