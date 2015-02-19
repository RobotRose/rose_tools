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

ln -s $ROBOT_CONFIG_FILE_TARGET $ROBOT_CONFIG_FILE_LINKNAME
if [ $? -eq 1 ]; then    
    echo "ERROR: Could not symlink $ROBOT_CONFIG_FILE_TARGET to $ROBOT_CONFIG_FILE_LINKNAME"
    exit 1
fi
echo "Linked $ROBOT_CONFIG_FILE_TARGET to $ROBOT_CONFIG_FILE_LINKNAME"

ROSE_SCRIPTS_FOLDER_FILE="/usr/bin/set_rose_scripts_folder.sh"

# Get the path of this file
THIS_FOLDER=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

echo "Creating $SCRIPTS_FILE"
echo -en '#!/bin/bash\nROSE_SCRIPTS=' > $ROSE_SCRIPTS_FOLDER_FILE
echo -e "${THIS_FOLDER}" >> $ROSE_SCRIPTS_FOLDER_FILE

chmod +x $ROSE_SCRIPTS_FOLDER_FILE

source $ROSE_SCRIPTS_FOLDER_FILE

echo "Copying ${ROSE_SCRIPTS}/colorize to /usr/bin/"
cp ${ROSE_SCRIPTS}/colorize /usr/bin/colorize

SETUP_ROBOT_ENV_SCRIPT="/usr/bin/setup_robot_env.sh"
ln -s $THIS_FOLDER/setup_env.sh $SETUP_ROBOT_ENV_SCRIPT

if [ $? -eq 1 ]; then    
    echo "ERROR: Could not symlink $THIS_FOLDER/setup_env.sh to $SETUP_ROBOT_ENV_SCRIPT"
    exit 1
fi
echo "Linked $THIS_FOLDER/setup_env.sh to $SETUP_ROBOT_ENV_SCRIPT"
