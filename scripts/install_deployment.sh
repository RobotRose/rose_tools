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
	echo "Installing deployment '${DEPLOYMENT_ID}'." | colorize BLUE
fi

# Check for existence of specified deployment
DEPLOYMENT_FILE="${WORKSPACE_ROOT}/deployment/src/rose_config/rose_config/deployment/${DEPLOYMENT_ID}/deployment.sh"

if [ -f ${DEPLOYMENT_FILE} ]; then
	echo "Deployment ${DEPLOYMENT_FILE} found." | colorize BLUE
else
	echo "Deployment ${DEPLOYMENT_FILE} non existing." | colorize RED
	exit 1
fi	

# Store old values
OLD_WS_ROOT=${WORKSPACE_ROOT}
OLD_CONFIG=${ROSE_CONFIG}
OLD_TOOLS=${ROSE_TOOLS}

# Check if we had a old workspace root
if [ ${OLD_WS_ROOT} == "" ]; then
	echo "No old workspace root detected." | colorize BLUE
else
	echo "Current workspace root is '${OLD_WS_ROOT}'" | colorize BLUE
fi

# Source new deployment file
source ${DEPLOYMENT_FILE}

# Store new values
NEW_WS_ROOT=${WORKSPACE_ROOT}
NEW_CONFIG=${ROSE_CONFIG}
NEW_TOOLS=${ROSE_TOOLS}

# Check if we now have a new workspace root
if [ ${NEW_WS_ROOT} == "" ]; then
	echo "No new workspace root detected." | colorize RED
	exit 1
else
	echo "New workspace root is '${NEW_WS_ROOT}'" | colorize BLUE
fi

# Extract old uris
OLD_URIS=${CURRENT_DIR}/extract_rosinstall_remotes.sh ${OLD_WS_ROOT}/.rosinstall
if [ $? == 0 ]; then
	exit 1
fi

# Extract new uris
NEW_URIS=${CURRENT_DIR}/extract_rosinstall_remotes.sh ${NEW_CONFIG}/deployment/${DEPLOYMENT_ID}/.rosinstall
if [ $? == 0 ]; then
	exit 1
fi

# For each OLD URI
while read -r OLD_URI; do
    # If old URI is in new .rosinstall
    if [ ${CURRENT_DIR}/compare_rosinstalls.sh ${NEW_WS_ROOT} contains_uri ${OLD_URI} == 100 ]; then
    	echo "$Old URI '${OLD_URI}' is in new .rosinstall."
    else
    	echo "$Old URI '${OLD_URI}' is NOT in new .rosinstall."
    fi
done <<< "$OLD_URIS"
