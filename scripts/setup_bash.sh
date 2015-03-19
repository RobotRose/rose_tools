#!/bin/bash  

# Setup the vars in robot_file.sh by sourcing the symlinked file in /usr/bin.
# This file is installed by running the first_install.sh script
ROBOT_FILE=$(readlink /usr/bin/robot_file.sh)
echo "ROBOT_FILE = $ROBOT_FILE"
if [ -f $ROBOT_FILE ]; then
	source $ROBOT_FILE
else
	echo "Could not find link target of /usr/bin/robot_file.sh -> ${ROBOT_FILE}. Did you run first_install.sh on this PC?" 
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
