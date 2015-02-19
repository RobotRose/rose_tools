#!/bin/bash  

 # Check if we are sudo user
if [ "$(id -u)" != "0" ]; then
    echo -e "Sorry, you should run this script as root."
    exit 1
fi

ROBOT_CONFIG_FILE_LINKNAME="/usr/bin/robot_file.sh"
ROBOT_CONFIG_FILE_TARGET=$1 #First cmd line arg. 

if [ -z $ROBOT_CONFIG_FILE_TARGET ]; then
        echo "ERROR: First parameter must be robot_<name>_config.sh file from $ roscd rose_config/robots."
        exit 1
fi

ln -s -f $ROBOT_CONFIG_FILE_TARGET $ROBOT_CONFIG_FILE_LINKNAME
if [ $? -eq 1 ]; then    
    echo "ERROR: Could not symlink $ROBOT_CONFIG_FILE_TARGET to $ROBOT_CONFIG_FILE_LINKNAME"
    exit 1
fi
echo "Linked $ROBOT_CONFIG_FILE_TARGET to $ROBOT_CONFIG_FILE_LINKNAME"
source $ROBOT_CONFIG_FILE_LINKNAME

echo "Copying ${ROSE_TOOLS}/scripts/colorize to /usr/bin/"
cp ${ROSE_TOOLS}/scripts/colorize /usr/bin/colorize

SETUP_ROBOT_ENV_SCRIPT="/usr/bin/setup_robot_env.sh"
ln -s -f $THIS_FOLDER/setup_env.sh $SETUP_ROBOT_ENV_SCRIPT

if [ $? -eq 1 ]; then    
    echo "ERROR: Could not symlink $THIS_FOLDER/setup_env.sh to $SETUP_ROBOT_ENV_SCRIPT"
    exit 1
fi
echo "Linked $THIS_FOLDER/setup_env.sh to $SETUP_ROBOT_ENV_SCRIPT"
