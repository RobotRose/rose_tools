#!/bin/bash  

# Select a deployment

DEPLOYMENT_GIT_DIR="${ROSE_CONFIG}/deployment"
eval DEPLOYMENT_USER_DIR="~/user_deployment"
selected_nr=-1


# Check if dialog is installed
dialog 2>&1 1> /dev/null

if [ $? == 127 ]; then
    echo "Installing dialog." | colorize BLUE
    apt-get install -y --force-yes dialog 
fi


nr_g="$(ls -A ${DEPLOYMENT_GIT_DIR}/ | grep -c "")"  
nr_u="$(ls -A ${DEPLOYMENT_USER_DIR}/ | grep -c "")" 
if [ "$nr_g" == "0" ]; then
	if [ "$nr_u" == "0" ]; then
    	echo "No deployments found in either '${DEPLOYMENT_GIT_DIR}'' or '${DEPLOYMENT_USER_DIR}'." | colorize RED
    	exit 1
    fi
fi

# Read git rosinstalls
i="0"
options=""
while [ $i -lt $nr_g ]
do
  new="$[$i+1] git/$(ls -A ${DEPLOYMENT_GIT_DIR}/ | sed -n $[$i+1]p) "
  echo "New option: $new"
  options="${options}${new}"
  i=$[$i+1]
done

# Read user rosinstalls
j="0"
while [ $j -lt $nr_u ]
do
  new="$[$i+1] user/$(ls -A ${DEPLOYMENT_USER_DIR}/ | sed -n $[$j+1]p) "
  echo "New option: $new"
  options="${options}${new}"
  i=$[$i+1]
  j=$[$j+1]
done

options2=($options)

dialog --title "Select deployment" \
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

DEPLOYMENT_ID=$(ls -A ${INSTALL_DIR}/ | sed -n ${dir_nr}p)
SELECTED_DEPLOYMENT_FILE="${INSTALL_DIR}/${DEPLOYMENT_ID}/deployment.sh"
echo "${SELECTED_DEPLOYMENT_FILE}" | colorize GREEN

# Do the actual 'selecting'
source ${ROSE_TOOLS}/scripts/install_deployment.sh ${DEPLOYMENT_ID} ${ROSE_CONFIG} ${ROSE_TOOLS} ${SELECTED_DEPLOYMENT_FILE}
