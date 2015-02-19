#!/bin/bash  

source $ROSE_TOOLS/scripts/setup_ROS.sh

cd $1
cd ../
rosmake --pre-clean
