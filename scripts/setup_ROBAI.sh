#!/bin/bash

echo 'Setting up Cyton arms...'  | colorize BLUE
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
	echo "Could not find the rose_third_party package, not setting up Cyton arms" | colorize RED
fi
