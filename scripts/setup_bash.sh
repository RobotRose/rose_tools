#!/bin/bash  

# Setup the rose scripts folder by running the set_rose_scripts_folder.sh in /usr/bin.
# This file is installed by running the first_install.sh script
source set_rose_scripts_folder.sh

if [ $? != 0 ]; then
	>&2 echo "Could not find the set_rose_scripts_folder script. Did you run first_install.sh on this PC?"
	read -p "Press CTRL+C to stop script or Enter to exit"
	exit 1
fi

echo "Adding the rose scripts dir to the PATH."
export PATH="$ROSE_SCRIPTS:$PATH"

echo -n 'ROSE_SCRIPTS = '  | colorize YELLOW
echo $ROSE_SCRIPTS

echo -n 'Adding bash aliases... ' | colorize BLUE
source $ROSE_SCRIPTS/bash_aliases.sh
echo 'done' | colorize GREEN
