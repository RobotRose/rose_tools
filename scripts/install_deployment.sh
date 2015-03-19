#!/bin/bash

# Read arguments
DEPLOYMENT_ID=$1

# Handy variables
CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Check if identifier was provided
if [ ${DEPLOYMENT_ID} == "" ]; then
	echo "No deployment identifier specified." | colorize RED
	exit 1
else
	echo "Installing deployment '${DEPLOYMENT_ID}." | colorize BLUE
fi

# Check for existence of specified deployment
DEPLOYMENT_FILE="${WORKSPACE_ROOT}/deployment/${DEPLOYMENT_ID}/deployment.sh"

if [ -f ${DEPLOYMENT_FILE} ]; then
	echo "Deployment ${DEPLOYMENT_FILE} non existing." | colorize RED
	exit 1
else
	echo "Deployment ${DEPLOYMENT_FILE} found." | colorize BLUE
fi	

# Store old values
OLD_WS_ROOT=${WORKSPACE_ROOT}

# Check if we had a old workspace root
if [ ${OLD_WS_ROOT} == "" ]; then
	echo "No workspace root detected." | colorize BLUE
else
	echo "Current workspace root is '${OLD_WS_ROOT}'" | colorize BLUE
fi

# Source new deployment file
source ${DEPLOYMENT_FILE}

# Store new values
NEW_WS_ROOT=${WORKSPACE_ROOT}

# Extract old uris
OLD_URIS=${CURRENT_DIR}/extract_rosinstall_remotes.sh ${OLD_WS_ROOT}/.rosinstall
if [ $? == 0 ]; then
	exit 1
fi

# Extract new uris
NEW_URIS=${CURRENT_DIR}/extract_rosinstall_remotes.sh ${NEW_WS_ROOT}/.rosinstall
if [ $? == 0 ]; then
	exit 1
fi

# For each OLD URI
while read -r OLD_URI; do
    # If old URI is in new .rosinstall
    if [ ${CURRENT_DIR}/compare_rosinstalls.sh ${NEW_WS_ROOT} contains_uri ${OLD_URI} == 100 ]; then
    	echo "$Old URI '{OLD_URI}' is in new .rosinstall."
    else
    	echo "$Old URI '{OLD_URI}' is NOT in new .rosinstall."
    fi
done <<< "$OLD_URIS"
