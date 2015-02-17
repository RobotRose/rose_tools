#!/usr/bin/env bash

echo "setup_env.sh: Running $(date)" > ~/setup_env.log

# Setup the rose scripts folder env variable ROSE_SCRIPTS by running the set_rose_scripts_folder.sh in /usr/bin.
# This file is installed by running the first_install.sh script
source set_rose_scripts_folder.sh >> ~/setup_env.log

echo "setup_env.sh: Set scripts folder to $ROSE_SCRIPTS" >> ~/setup_env.log

if [ $? != 0 ]; then
	echo "Could not find the set_rose_scripts_folder script. Did you run first_install.sh on this PC?"
	echo "setup_env.sh: ERROR" >> ~/log.txt
	exit 1
fi

# Set the robot file
export ROBOT_FILE=$1
echo "setup_env.sh: ROBOT_FILE = $ROBOT_FILE" >> ~/setup_env.log

source $ROBOT_FILE
echo "setup_env.sh: Sourced robot file." >> ~/setup_env.log

IP=`ifconfig tap0 | grep 'inet addr:'  | cut -d: -f2 | awk '{ print $1}'`
echo "setup_env.sh: tap0 IP = $IP" >> ~/setup_env.log

echo "setup_env.sh: Sourcing setup_ROS.sh." >> ~/setup_env.log
source $ROSE_SCRIPTS/setup_ROS.sh "/opt/ros/hydro/" "$IP" "http://rosepc1:11311" >> ~/setup_env.log

shift
echo "setup_env.sh: Executing arguments: $@ " >> ~/setup_env.log
exec "$@"

echo "setup_env.sh: Done " >> ~/setup_env.log
