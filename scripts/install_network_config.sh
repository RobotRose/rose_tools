#!/bin/bash

WPA_SUPPLICANT_CONF="/etc/wpa_supplicant/wpa_supplicant_ap-switcher.conf"
WPA_SUPPLICANT_CONF_BASE="${ROSE_TOOLS}/scripts/default_wpa_supplicant.conf"

echo "Encrypted wpa_supplicant WPA2 configuration installer."

# Check if we are sudo user
if [ "$(id -u)" == "0" ]; then
    echo -e "Sorry, you should NOT run this script as root." | colorize RED
    exit 1
fi

if [ "${LOCATIONS_ROOT}" == "" ] || [ ! -d ${LOCATIONS_ROOT} ]; then
	echo "Installations root dir LOCATIONS_ROOT not set." | colorize RED
	exit 1
fi

echo "Please provide the installation id " | colorize BLUE
read INSTALL_ID

LOCATION_DIR="${LOCATIONS_ROOT}/${INSTALL_ID}"

if [ "${INSTALL_ID}" == "" ] || [ ! -d "${LOCATION_DIR}" ]; then
	echo "Invalid installation provided: ${LOCATION_DIR}" | colorize RED
	exit 1
fi

NETWORK_FILE="${LOCATION_DIR}/network.conf"

if [ ! -f ${NETWORK_FILE} ]; then
	echo "Could not find network configuration file: ${NETWORK_FILE}." | colorize RED
	exit 1
fi

# Make backup and remove original if there is already a configuration file
if [ -f ${WPA_SUPPLICANT_CONF} ]; then
	echo "Creating backup of ${WPA_SUPPLICANT_CONF}." | colorize GREEN
	sudo -E bash -c "cp -f ${WPA_SUPPLICANT_CONF} ${WPA_SUPPLICANT_CONF}.bak"
	sudo -E bash -c "rm ${WPA_SUPPLICANT_CONF}"
fi

# Decrypt
sudo -E bash -c "gpg -o ${WPA_SUPPLICANT_CONF} -d ${NETWORK_FILE}"
GPG_SUCCESS=$?

# Insert wpa_supplicant global base configuration at beginning of the file
sudo -E bash -c "echo -e \"$(cat ${WPA_SUPPLICANT_CONF_BASE})\n$(cat ${WPA_SUPPLICANT_CONF})\" > ${WPA_SUPPLICANT_CONF}"
SED_SUCCESS=$?

# Check if successful
if [ ${GPG_SUCCESS} != 0 ] || [ ${SED_SUCCESS} != 0 ]; then
	echo "Could not decrypt the network configuration ${NETWORK_FILE}." | colorize RED
	echo "Restoring backup..." | colorize YELLOW
	sudo -E bash -c "mv ${WPA_SUPPLICANT_CONF}.bak ${WPA_SUPPLICANT_CONF}"
	exit 1
else
	echo "Configuration decrypted and written to ${WPA_SUPPLICANT_CONF}." | colorize GREEN
	if [ -f "${WPA_SUPPLICANT_CONF}.bak" ]; then
		echo "Removing backup..." | colorize GREEN
		sudo -E bash -c "rm ${WPA_SUPPLICANT_CONF}.bak > /dev/null 2>&1"
	fi
fi

