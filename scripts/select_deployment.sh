#!/bin/bash  
# Bash Menu Script Example

# Setup the vars in robot_file.sh by sourcing the symlinked file in /usr/bin.
# This file is installed by running the first_install.sh script
source robot_file.sh

# Set up bash aliases and ROSE_TOOLS/scripts env variable, assumes this script is in same directory as this script
source $ROSE_TOOLS/scripts/setup_bash.sh

DEPLOYMENT_GIT_DIR="${ROSE_CONFIG}/deployment"
eval DEPLOYMENT_USER_DIR="~/.deployment"
selected_nr=-1


# Check if dialog is installed
dialog 2>&1 1> /dev/null

if [ $? == 127 ]; then
    echo "Installing dialog." | colorize BLUE
    apt-get install -y --force-yes dialog 
fi

# Check if $WORKSPACE_ROOT is defined
if [ -e $WORKSPACE_ROOT ]; then
	dialog --title "Deployment folders" \
	--backtitle "Deployment folders" \
	--colors \
	--nocancel \
	--pause "WORKSPACE_ROOT = \Z3${WORKSPACE_ROOT}\Zn \nDEPLOYMENT_GIT_DIR = \Z3${DEPLOYMENT_GIT_DIR}\Zn \nDEPLOYMENT_USER_DIR = \Z3${DEPLOYMENT_USER_DIR}\Zn \n" 10 120 2
else
	echo "No workspace root configured in $(readlink -f /usr/bin/robot_file.sh)." | colorize RED
	exit 1
fi

nr_g="$(ls -a ${DEPLOYMENT_GIT_DIR}/ | grep -c deployment)"  
nr_u="$(ls -a ${DEPLOYMENT_USER_DIR}/ | grep -c deployment)" 
if [ "$nr_g" == "0" ]; then
	if [ "$nr_u" == "0" ]; then
    	echo "No deployments found in either '${DEPLOYMENT_GIT_DIR}'' or '${DEPLOYMENT_USER_DIR}'." | colorize RED
    	exit 1
    fi
fi

# Read git deployments
i="0"
options=""
while [ $i -lt $nr_g ]
do
  new="$[$i+1] git/$(ls -a ${DEPLOYMENT_GIT_DIR}/ | grep deployment | sed -n $[$i+1]p) "
  echo "New option: $new"
  options="${options}${new}"
  i=$[$i+1]
done

# Read user deployments
j="0"
while [ $j -lt $nr_u ]
do
  new="$[$i+1] user/$(ls -a ${DEPLOYMENT_USER_DIR}/ | grep deployment | sed -n $[$j+1]p) "
  echo "New option: $new"
  options="${options}${new}"
  i=$[$i+1]
  j=$[$j+1]
done

options2=($options)

dialog --title "Select deployment file" \
	--backtitle "Select deployment" \
	--clear \
	--menu "Select a deployment:" 40 80 22 ${options2[@]} 2>/tmp/vpn_dialog.ans

result=$(cat /tmp/vpn_dialog.ans)
if [ "$result" == "" ]; then
    echo "Canceled." | colorize BLUE
    exit 1
fi
selected_nr=$result

if [[ $selected_nr -lt $nr_g ]]; then
	INSTALL_DIR=${DEPLOYMENT_GIT_DIR}
	dir_nr=$selected_nr
else
	INSTALL_DIR=${DEPLOYMENT_USER_DIR}
	dir_nr=$[$selected_nr-$nr_g]
fi

selected="$(ls -a ${INSTALL_DIR}/ | grep deployment | sed -n ${dir_nr}p)"
echo -en "${selected}" | colorize GREEN
echo " -> file $dir_nr from '${INSTALL_DIR}'" | colorize BLUE

# Do the actual 'selecting'
# Copy deployment to the deployment root directory
cp -f ${INSTALL_DIR}/${selected} ${WORKSPACE_ROOT}/.deployment

dialog --colors \
	--title "Select deployment file" \
	--backtitle "Run git-update-all?" \
	--defaultno \
	--yesno "Selected \Z2${selected}\Zn -> \Z4${INSTALL_DIR}\Zn.\n\Zb\Z1Do you want to run git-update-all now?\Zn" 7 120

# Get exit status
# 0 means user hit [yes] button.
# 1 means user hit [no] button.
# 255 means user hit [Esc] key.
response=$?
case $response in
   0) 
	echo "Running git-update-all..." | colorize BLUE
	#git-update-all 
	
	echo "Do you want to run 'cm all'?" | colorize BLUE
	select yn in "Yes" "No"; do
	    case $yn in
	        Yes ) echo "Running 'cm all'" | colorize BLUE; cm all; break;;
	        No ) exit 0;;
	    esac
	done
	;;
   1) 
	echo "Not running git-update-all." | colorize BLUE
	;;
   255);;
esac

# Robot model
source ${ROSE_CONFIG}/models/model_${ROBOT_NAME}.config

# Robot model
source ${ROSE_CONFIG}/models/${ROBOT_NAME}/model.sh

# Location
source ${ROSE_CONFIG}/locations/${LOCATION_NAME}/location.sh
