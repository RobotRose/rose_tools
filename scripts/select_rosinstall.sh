#!/bin/bash  
# Bash Menu Script Example

# Setup the vars in robot_file.sh by sourcing the symlinked file in /usr/bin.
# This file is installed by running the first_install.sh script
source robot_file.sh

# Set up bash aliases and ROSE_TOOLS/scripts env variable, assumes this script is in same directory as this script
source $ROSE_TOOLS/scripts/setup_bash.sh

ROSINSTALL_GIT_DIR="${ROSE_CONFIG}/rosinstall"
eval ROSINSTALL_USER_DIR="~/.rosinstall"
selected_nr=-1


# Check if dialog is installed
dialog 2>&1 1> /dev/null

if [ $? == 127 ]; then
    echo "Installing dialog." | colorize BLUE
    apt-get install -y --force-yes dialog 
fi

# Check if $ROSINSTALL_ROOT is defined
if [ -e $ROSINSTALL_ROOT ]; then
	dialog --title "rosinstall root" \
	--backtitle "Checking for rosinstall root" \
	--colors \
	--sleep 2 \
	--infobox "ROSINSTALL_ROOT = \Z3${ROSINSTALL_ROOT}\Zn \nROSINSTALL_GIT_DIR = \Z3${ROSINSTALL_GIT_DIR}\Zn \nROSINSTALL_USER_DIR = \Z3${ROSINSTALL_USER_DIR}\Zn \n" 5 120
	# echo -n "ROSINSTALL_ROOT = " | colorize YELLOW
	# echo "${ROSINSTALL_ROOT}"
else
	echo "No rosinstall root configured in $(readlink -f /usr/bin/robot_file.sh)." | colorize RED
	exit 1
fi

nr_g="$(ls -a ${ROSINSTALL_GIT_DIR}/ | grep -c rosinstall)"
nr_u="$(ls -a ${ROSINSTALL_USER_DIR}/ | grep -c rosinstall)"
if [ "$nr_g" == "0" ]; then
	if [ "$nr_u" == "0" ]; then
    	echo "No rosinstalls found in either '${ROSINSTALL_GIT_DIR}'' or '${ROSINSTALL_USER_DIR}'." | colorize RED
    	exit 1
    fi
fi

# Read git rosinstalls
i="0"
options=""
while [ $i -lt $nr_g ]
do
  new="$[$i+1] git/$(ls -a ${ROSINSTALL_GIT_DIR}/ | grep rosinstall | sed -n $[$i+1]p) "
  echo "New option: $new"
  options="${options}${new}"
  i=$[$i+1]
done

# Read user rosinstalls
j="0"
while [ $j -lt $nr_u ]
do
  new="$[$i+1] user/$(ls -a ${ROSINSTALL_USER_DIR}/ | grep rosinstall | sed -n $[$j+1]p) "
  echo "New option: $new"
  options="${options}${new}"
  i=$[$i+1]
  j=$[$j+1]
done

options2=($options)

dialog --title "Select rosinstall file" \
	--backtitle "Select rosinstall" \
	--clear \
	--menu "Select a rosinstall:" 40 80 22 ${options2[@]} 2>/tmp/vpn_dialog.ans

result=$(cat /tmp/vpn_dialog.ans)
if [ "$result" == "" ]; then
    echo "Canceled." | colorize BLUE
    exit 1
fi
selected_nr=$result

if [[ $selected_nr -lt $nr_g ]]; then
	INSTALL_DIR=${ROSINSTALL_GIT_DIR}
	dir_nr=$selected_nr
else
	INSTALL_DIR=${ROSINSTALL_USER_DIR}
	dir_nr=$[$selected_nr-$nr_g]
fi

selected="$(ls -a ${INSTALL_DIR}/ | grep rosinstall | sed -n ${dir_nr}p)"
echo -en "${selected}" | colorize GREEN
echo " -> file $dir_nr from '${INSTALL_DIR}'" | colorize BLUE

# Do the actual 'selecting'
# Copy rosinstall to the rosinstall root directory
cp -f ${INSTALL_DIR}/${selected} ${ROSINSTALL_ROOT}/.rosinstall

dialog --colors \
	--title "Select rosinstall file" \
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
	temp_file=$(mktemp)
	echo " " > $temp_file
	dialog --sleep 1
	git-update-all > "$temp_file" 2>&1 &
	dialog --title "Select rosinstall file" \
		--backtitle "Running git-update-all" \
		--tailbox "$temp_file" 120 150
	rm "$temp_file"
	;;
   1) 
	echo "Not running git-update-all..." | colorize BLUE
	;;
   255);;
esac
