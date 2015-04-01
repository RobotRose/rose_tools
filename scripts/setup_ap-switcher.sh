#!/bin/bash

FILENAME="ap-switcher"
NETWORK_SWITCHER_FILE="${ROSE_TOOLS}/scripts/${FILENAME}"
NETWORK_SWITCHER_LINK="/etc/init.d/${FILENAME}"

echo "Setting up ap-switcher..."

sudo -E bash -c "ln -fs ${NETWORK_SWITCHER_FILE} ${NETWORK_SWITCHER_LINK}"
LINK_SUCCESS=$?

sudo -E bash -c "update-rc.d ${FILENAME} defaults"
UPDATERC_SUCCESS=$?

if [ $LINK_SUCCESS == 0 ] && [ $UPDATERC_SUCCESS == 0 ]; then
	echo "Successfully setup ap-switcher." | colorize GREEN
else
	echo "Error setting up ap-switcher." | colorize RED
	exit 1
fi
