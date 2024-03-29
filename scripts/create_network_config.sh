#!/bin/bash
# Create an encrypted WPA2 network.conf file for use with wpa_supplicant

echo "Encrypted wpa_supplicant WPA2 configuration creator."

if [ "${LOCATIONS_ROOT}" == "" ] || [ ! -d ${LOCATIONS_ROOT} ]; then
	echo "Installations root dir LOCATIONS_ROOT not set" | colorize RED
	exit 1
fi

echo -n "Please enter WPA2 SSID: " | colorize BLUE
read SSID
echo -n "Please enter WPA2 pass phrase: " | colorize BLUE
read -s PASS
echo

RAW=$(wpa_passphrase $SSID $PASS)
if [ $? != 0 ]; then
	echo "Error generating configuration." | colorize RED
	RAW=""
	exit 1
fi
CONFIG=$(echo -en "$RAW" | grep -v "#")

echo "Configuration created:" | colorize GREEN
echo -e "${CONFIG}"

echo "For which (existing) location id is this network configuration? " | colorize BLUE
read LOCATION_ID

LOCATION_DIR="${LOCATIONS_ROOT}/${LOCATION_ID}"

if [ "${LOCATION_ID}" == "" ] || [ ! -d "${LOCATION_DIR}" ]; then
	echo "Invalid location id provided: ${LOCATION_DIR}" | colorize RED
	exit 1
fi

NETWORK_FILE="${LOCATION_DIR}/network.conf"

if [ -f ${NETWORK_FILE} ]; then
	echo -en "File exists: ${NETWORK_FILE}\nOverwrite? [y/N] " | colorize YELLOW
	read -r response
	case $response in
	    [yY]) 
	        ;;
	    *)
	        exit 1
	        ;;
	esac
	cp -f "${NETWORK_FILE}" "${NETWORK_FILE}.bak"
	rm "${NETWORK_FILE}" 
fi

echo -en "${CONFIG}" | gpg --batch -c -o ${NETWORK_FILE}
GPG_SUCCESS=$?

if [ ${GPG_SUCCESS} != 0 ]; then
	echo "Could not encrypt and write configuration to ${NETWORK_FILE}." | colorize RED
	echo "Restoring backup..." | colorize YELLOW
	mv "${NETWORK_FILE}.bak" "${NETWORK_FILE}"
	exit 1
else
	echo "Configuration encrypted and written to ${NETWORK_FILE}." | colorize GREEN
	if [ -f "${NETWORK_FILE}.bak" ]; then
		echo "Removing backup..." | colorize GREEN
		rm "${NETWORK_FILE}.bak"
	fi
fi
