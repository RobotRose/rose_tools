#!/usr/bin/env bash

# Update library path
echo 'Updating library path...' | colorize BLUE
export LD_LIBRARY_PATH=/opt/ros/hydro/lib/:/usr/lib/gazebo-1.9/plugins #:~/git/rose2_0/simulator/devel/lib
echo -n 'LD_LIBRARY_PATH = ' | colorize YELLOW
echo $LD_LIBRARY_PATH


