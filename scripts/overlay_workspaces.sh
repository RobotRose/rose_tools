#!bin/bash

#Overlay workspaces
echo 'Overlaying catkin workspaces...' | colorize BLUE
for WORKSPACE in `get-all-workspace-paths`
do
	echo -n ' Workspace setup file: '| colorize YELLOW

	echo -n ${WORKSPACE}/devel/setup.sh

	if [ -f ${WORKSPACE}/devel/setup.sh ]; then
		source ${WORKSPACE}/devel/setup.sh --extend
		echo " overlayed." | colorize GREEN
	else
		echo " does not exist." | colorize RED
	fi
done
