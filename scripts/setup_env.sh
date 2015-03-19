#!/usr/bin/env bash

echo "setup_env.sh: Running $(date)" > ~/setup_env.log

# Setup the rose scripts folder env variable ROSE_TOOLS/scripts by running the robot_file.sh in /usr/bin.
# This file is installed by running the first_install.sh script
ROBOT_FILE=$(readlink /usr/bin/robot_file.sh)
echo "ROBOT_FILE = $ROBOT_FILE"
if [ -f $ROBOT_FILE ]; then
	source $ROBOT_FILE >> ~/setup_env.log
else
	echo "Could not find link target of /usr/bin/robot_file.sh -> ${ROBOT_FILE}. Did you run first_install.sh on this PC?" 
	read -p "Press CTRL+C to stop script or Enter to exit"
	exit 1
fi

echo "setup_env.sh: Set scripts folder to $ROSE_TOOLS/scripts" >> ~/setup_env.log

# Set the robot file
export ROBOT_FILE=$(readlink -f /usr/bin/robot_file.sh)
echo "setup_env.sh: ROBOT_FILE = $ROBOT_FILE" >> ~/setup_env.log

source $ROBOT_FILE
echo "setup_env.sh: Sourced robot file." >> ~/setup_env.log

IP=`ifconfig tap0 | grep 'inet addr:'  | cut -d: -f2 | awk '{ print $1}'`
echo "setup_env.sh: tap0 IP = $IP" >> ~/setup_env.log

echo "setup_env.sh: Sourcing setup_ROS.sh." >> ~/setup_env.log
source $ROSE_TOOLS/scripts/setup_ROS.sh "/opt/ros/hydro/" "$IP" "http://rosepc1:11311" >> ~/setup_env.log

echo "setup_env.sh: Executing arguments: $@ " >> ~/setup_env.log
exec "$@"

echo "setup_env.sh: Done " >> ~/setup_env.log
