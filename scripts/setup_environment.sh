#!/bin/bash  

DEPLOYMENT_SCRIPT="/usr/bin/deployment_script.sh"
DEPLOYMENT_FILE="/usr/bin/deployment_file.sh"

# Activate Deployment
if [ -e ${DEPLOYMENT_SCRIPT} ]; then
	if [ -e ${DEPLOYMENT_FILE} ]; then	
		source ${DEPLOYMENT_SCRIPT} $(readlink ${DEPLOYMENT_FILE})
	else
		echo "Deployment file '$(readlink ${DEPLOYMENT_FILE})' not found." | colorize RED
	fi
else
	echo "Deployment script '$(readlink ${DEPLOYMENT_SCRIPT})' not found." | colorize RED
fi

echo -n 'WORKSPACES FILE = ' | colorize YELLOW
echo ${WORKSPACES_FILE}

# Setup ROS environment
source "${ROSE_TOOLS}/scripts/setup_ROS.sh"

# Setup ROBAI arms
source ${ROSE_TOOLS}/scripts/setup_ROBAI.sh 

echo -n 'Setup git... ' | colorize BLUE
source ${ROSE_TOOLS}/scripts/setup_git.sh
echo 'done'  | colorize GREEN
echo

#save history after every command
#use 'history -r' to reload history
PROMPT_COMMAND="history -a ; ${PROMPT_COMMAND}"

echo "Setup of the environment done, enjoy!" | colorize GREEN
