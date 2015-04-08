#!/bin/bash

# This sets up the ap-switcher script in rc.d such that wpa_supplicant and dhclient will be started at boot.
# This needs to be re-run when moving the rose_tools package.

FILENAME="boot_rose.sh"
FILE="${ROSE_TOOLS}/scripts/${FILENAME}"
LINK="/etc/init.d/${FILENAME}"

echo "Setting up ${FILENAME}..."

sudo -E bash -c "ln -fs ${FILE} ${LINK}"
LINK_SUCCESS=$?

if [ $LINK_SUCCESS != 0 ]
	echo "Could not create link ${LINK} -> ${FILE}."
	exit 1
else
	echo "Link ${LINK} -> ${FILE} created."
fi

sudo -E bash -c "update-rc.d -f ${FILENAME} defaults"
UPDATERC_SUCCESS=$?

if [ $UPDATERC_SUCCESS == 0 ]; then
	echo "Successfully setup ap-switcher." | colorize GREEN
else
	echo "Error setting up ap-switcher." | colorize RED
	exit 1
fi
