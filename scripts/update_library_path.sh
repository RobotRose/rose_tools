#!/bin/bash

# Update library path
echo 'Updating library path...' | colorize BLUE
export LD_LIBRARY_PATH=/opt/ros/hydro/lib/:/usr/lib/gazebo-1.9/plugins #:~/git/rose2_0/simulator/devel/lib
echo -n 'LD_LIBRARY_PATH = ' | colorize YELLOW
echo $LD_LIBRARY_PATH

echo 'Trying to set up Cyton arms...'  | colorize BLUE
THIRD_PARTY_LOCATION=`rospack find rose_third_party`

if [ $? == 0 ]; then
	export EC_LOCATION=${THIRD_PARTY_LOCATION}/robai
	echo -n 'EC_LOCATION = ' | colorize YELLOW
	echo $EC_LOCATION

	# Adding Robai lib/bin to LD_LIBRARY_PATH
	export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$EC_LOCATION/bin:$EC_LOCATION/lib
	echo -n 'LD_LIBRARY_PATH = ' | colorize YELLOW
	echo $LD_LIBRARY_PATH
else
	echo "Could not find the rose_third_party, not setting up Cyton arms" | colorize RED
fi
