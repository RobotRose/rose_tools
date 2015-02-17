#!bin/bash

#Overlay workspaces
echo 'Overlaying catkin workspaces...' | colorize BLUE
for ws in `get-all-ws-paths`
do
	echo -n ' Workspace setup file: '| colorize YELLOW

	echo -n $ws/devel/setup.sh

	if [ -f $ws/devel/setup.sh ]; then
		source $ws/devel/setup.sh --extend
		echo " overlayed." | colorize GREEN
	else
		echo " does not exist." | colorize RED
	fi
done
