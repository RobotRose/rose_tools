#!/bin/bash

# This sets up the ap-switcher script in rc.d such that wpa_supplicant and dhclient will be started at boot.
# This needs to be re-run when moving the rose_tools package.

# Check if we are sudo user
if [ "$(id -u)" == "0" ]; then
    echo -e "Sorry, you should NOT run this script as root."
    return 1
fi

FILENAME="boot_rose.py"
FILE="${ROSE_TOOLS}/scripts/${FILENAME}"
LINK="/etc/init.d/${FILENAME}"

echo "Setting up ${FILENAME}..."

sudo -E bash -c "ln -fs ${FILE} ${LINK}"
LINK_SUCCESS=$?

if [ $LINK_SUCCESS != 0 ]; then
	echo "Could not create link ${LINK} -> ${FILE}."
	exit 1
else
	echo "Link ${LINK} -> ${FILE} created."
fi

sudo -E bash -c "update-rc.d -f ${FILENAME} defaults 99 05"
UPDATERC_SUCCESS=$?

if [ $UPDATERC_SUCCESS == 0 ]; then
	echo "Successfully setup ap-switcher." | colorize GREEN
else
	echo "Error setting up ap-switcher." | colorize RED
	exit 1
fi
