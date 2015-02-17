#!/bin/bash  

source $ROSE_SCRIPTS/setup_ROS.sh

cd $1
cd ../
rosmake
