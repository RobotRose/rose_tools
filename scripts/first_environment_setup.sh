#!/bin/bash  

 # Check if we are not sudo user
if [ "$(id -u)" == "0" ]; then
    echo -e "Sorry, you should not run this script as root."
    exit 1
fi

echo "This script should be run from the rose scripts folder."
sleep 2

# This will install the script in usr/bin which loads the ROSE_SCRIPTS folder
echo "Running first_install.sh"
sudo $( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/first_install.sh

# Setup the rose scripts folder by running the set_rose_scripts_folder.sh in /usr/bin.
# This file is installed by running the first_install.sh script
source set_rose_scripts_folder.sh

if [ $? != 0 ]; then
	echo "Could not find the set_rose_scripts_folder script. Did you run first_install.sh on this PC?"
	exit 1
fi

# Set up bash aliases and ROSE_SCRIPTS env variable, assumes this script is in same directory as this script
source $ROSE_SCRIPTS/setup_bash.sh

echo "Copying the default bashrc to ~/.bashrc"
cp $ROSE_SCRIPTS/default_bashrc ~/.bashrc; 
echo "Done. "

read -p "What is the full path of the robot file? " ROBOT_FILE
echo $ROBOT_FILE >> ~/ROBOT_FILE_LOCATION

source ~/.bashrc

# First compile
echo "Running first_compile.sh"
source $ROSE_SCRIPTS/first_compile.sh $ROBOT_FILE

source ~/.bashrc
