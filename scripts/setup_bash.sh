#!/bin/bash  

# Setup the vars in robot_file.sh by sourcing the symlinked file in /usr/bin.
# This file is installed by running the first_install.sh script
source robot_file.sh

if [ $? != 0 ]; then
	>&2 echo "Could not find the set_rose_scripts_folder script. Did you run first_install.sh on this PC?"
	read -p "Press CTRL+C to stop script or Enter to exit"
	exit 1
fi

echo "Adding the rose scripts dir to the PATH."
export PATH="$ROSE_TOOLS/scripts:$PATH"

echo -n 'ROSE_TOOLS/scripts = '  | colorize YELLOW
echo $ROSE_TOOLS/scripts

echo -n 'Adding bash aliases... ' | colorize BLUE
source $ROSE_TOOLS/scripts/bash_aliases.sh
echo 'done' | colorize GREEN
