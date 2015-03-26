#!/bin/bash

# Use provided argument if given, otherwise use ROS_INTERFACE
INTERFACE=${ROS_INTERFACE}
if [ "$1" != "" ]; then
	INTERFACE=$1
fi

if [ "${INTERFACE}" == "" ]; then
	echo "No interface provided. Not setting ROS_IP." | colorize RED
	return 1
fi

if [ $(ifconfig | grep -c ${INTERFACE}) == 0 ]; then
	echo "Could not find interface '${INTERFACE}'. Not setting ROS_IP." | colorize RED
	return 1
fi

#Get the IP you use with the provided interface
IP=$(ifconfig ${INTERFACE} | grep 'inet addr:'  | cut -d: -f2 | awk '{ print $1}')
if [ "$IP" == "" ]; then
	echo "Could not find ip of interface '${INTERFACE}'. Not setting ROS_IP." | colorize RED
	return 1
else
	export ROS_IP=${IP}
	echo -en "Setting ROS_IP to ip of interface '${INTERFACE}' = " | colorize BLUE
	echo "${ROS_IP}" | colorize YELLOW
fi
