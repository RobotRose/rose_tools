#!/bin/bash  

 # Check if we are not sudo user
if [ "$(id -u)" == "0" ]; then
    echo -e "Sorry, you should not run this script as root."
    exit 1
fi

echo "This script should be run from the rose scripts folder."
sleep 2

# This will install the script in usr/bin which loads the ROSE_TOOLS/scripts folder
echo "Running first_install.sh"
sudo $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/first_install.sh

# Setup the vars in robot_file.sh by sourcing the symlinked file in /usr/bin.
# This file is installed by running the first_install.sh script
source robot_file.sh

if [ $? != 0 ]; then
	echo "Could not find /usr/bin/robot_file.sh. Did you run first_install.sh on this PC?"

 
	exit 1
fi

# Set up bash aliases and ROSE_TOOLS/scripts env variable, assumes this script is in same directory as this script
source $ROSE_TOOLS/scripts/setup_bash.sh

echo "Copying the default bashrc to ~/.bashrc"
cp $ROSE_TOOLS/scripts/default_bashrc ~/.bashrc; 
echo "Done. "

read -p "What is the full path of the robot file? " ROBOT_FILE
echo $ROBOT_FILE >> ~/ROBOT_FILE_LOCATION

source ~/.bashrc

# First compile
echo "Running first_compile.sh"
source $ROSE_TOOLS/scripts/first_compile.sh $ROBOT_FILE

source ~/.bashrc
