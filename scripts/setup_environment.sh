#!/bin/bash  

DEPLOYMENT_SCRIPT="/usr/bin/deployment_script.sh"
DEPLOYMENT_FILE="/usr/bin/deployment_file.sh"

while getopts ":s:d:" opt; do
  case $opt in
    s)
      echo "Using $OPTARG ad deployment script." >&2
      DEPLOYMENT_SCRIPT=$OPTARG
      ;;
    d)
      echo "Using $OPTARG ad deployment file." >&2
      DEPLOYMENT_FILE=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

# Activate Deployment
if [ -e ${DEPLOYMENT_SCRIPT} ]; then
	if [ -e ${DEPLOYMENT_FILE} ]; then	
		source ${DEPLOYMENT_SCRIPT} ${DEPLOYMENT_FILE}
	else
		>&2 echo "Deployment file ${DEPLOYMENT_FILE} | $(readlink -f ${DEPLOYMENT_FILE}) not found." | colorize RED
	fi
else
	>&2 echo "Deployment script ${DEPLOYMENT_SCRIPT} | $(readlink -f ${DEPLOYMENT_SCRIPT}) not found." | colorize RED
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
