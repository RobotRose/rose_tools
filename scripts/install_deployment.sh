#!/bin/bash

# Check if we are sudo user
if [ "$(id -u)" == "0" ]; then
    echo -e "Sorry, you should NOT run this script as root."
    return 1
fi

# Read arguments
DEPLOYMENT_ID=$1 		 # Deployment ID as in current 'old' install
FORCE_ROSE_CONFIG=$2	 # Full path to rose_config package
FORCE_ROSE_TOOLS=$3		 # Full path to rose_config package
FORCE_DEPLOYMENT_FILE=$4 # Full path to a deployment file

# Handy variables
CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
CONFIG_FORCED=false
TOOLS_FORCED=false
DEPLOYMENT_FORCED=false

# Check if identifier was provided
if [ "${DEPLOYMENT_ID}" == "" ]; then
	echo "No deployment identifier specified." | colorize RED
	return 1
else
	echo -en "Installing deployment: " | colorize BLUE
	echo "${DEPLOYMENT_ID}" | colorize YELLOW
fi

# Store old values
OLD_REPOS_ROOT=${REPOS_ROOT}
OLD_ROSINSTALL_ROOT=${OLD_REPOS_ROOT}

# Check if we had a old repositories root
if [ "${OLD_REPOS_ROOT}" == "" ]; then
	echo "No old repositories root detected." | colorize BLUE
	HAVE_OLD_REPOS_ROOT=false
else
	echo -en "Current old repositories root is: " | colorize BLUE 
	echo "${OLD_REPOS_ROOT}" | colorize YELLOW
	HAVE_OLD_REPOS_ROOT=true
fi

if [ "$FORCE_ROSE_CONFIG" == "" ]; then
	OLD_CONFIG=${ROSE_CONFIG}
else
	OLD_CONFIG=${FORCE_ROSE_CONFIG}
	CONFIG_FORCED=true
fi

if [ "$FORCE_ROSE_TOOLS" == "" ]; then
	OLD_TOOLS=${ROSE_TOOLS}
else
	OLD_TOOLS=${FORCE_ROSE_TOOLS}
	TOOLS_FORCED=true
fi

echo -en "Using OLD_CONFIG: " | colorize BLUE
echo "${OLD_CONFIG}" | colorize YELLOW
echo -en "Using OLD_TOOLS: " | colorize BLUE
echo "${OLD_TOOLS}" | colorize YELLOW

# Prompt user for entering sudo password at this time, such that the whole script continues at once
sudo ls  > /dev/null 2>&1
if [ $? != 0 ]; then
	return 1
fi

# Promt user for github account username and password
pushd . > /dev/null 2>&1
cd ${OLD_TOOLS} > /dev/null 2>&1
git fetch > /dev/null 2>&1
popd > /dev/null 2>&1


if [ "$FORCE_DEPLOYMENT_FILE" == "" ]; then
	NEW_DEPLOYMENT_FILE="${OLD_CONFIG}/deployment/${DEPLOYMENT_ID}/deployment.sh"
else
	NEW_DEPLOYMENT_FILE="${FORCE_DEPLOYMENT_FILE}"
fi

OLD_DEPLOYMENT_FILE="$(readlink /usr/bin/deployment_file.sh)"

# Check if we have a path to the rose_config package
if [ "${OLD_CONFIG}" == "" ]; then
	echo "No rose_config package detected, provide as 2nd argument." | colorize RED
	return 1
fi
# Check if we have a path to the rose_tools package
if [ "${OLD_TOOLS}" == "" ]; then
	echo "No rose_tools package detected, provide as 3th argument." | colorize RED
	return 1
fi

# Check for existence of the new deployment file to
if [ -f ${NEW_DEPLOYMENT_FILE} ]; then
	echo "Deployment ${NEW_DEPLOYMENT_FILE} found." | colorize BLUE
else
	echo "Deployment ${NEW_DEPLOYMENT_FILE} is non existing." | colorize RED
	return 1
fi	

# Source PC_ID if it exists, otherwise ask.
source ${OLD_TOOLS}/scripts/pc_id.sh "" ""
echo -en "Using PC_ID: " | colorize BLUE
echo "${PC_ID}" | colorize YELLOW

# Source deployment and its corresponding installation file to read its parameters
source ${NEW_DEPLOYMENT_FILE}
source ${OLD_CONFIG}/installations/${ROBOT_INSTALLATION}/${PC_ID}.sh

# Store new values
NEW_REPOS_ROOT=${HOME}/${REPOS_LOCATION}
NEW_ROSINSTALL_OLD_ROOT="${OLD_CONFIG}/rosinstall/${ROSINSTALL}"

# Check if we now have a new repositories root
if [ ${NEW_REPOS_ROOT} == "" ]; then
	echo "No new repositories root detected." | colorize RED
	return 1
else
	echo -en "New repositories root is: " | colorize BLUE 
	echo "${NEW_REPOS_ROOT}" | colorize YELLOW
fi

echo -en "New .rosintall, located at old rose_config: " | colorize BLUE
echo "${NEW_ROSINSTALL_OLD_ROOT}" | colorize YELLOW

# If we had an previous 'old' install, check difference
if [ "${HAVE_OLD_REPOS_ROOT}" == true ]; then

	# Extract old uris
	OLD_URIS=$(${OLD_TOOLS}/scripts/extract_rosinstall_uris.sh ${OLD_ROSINSTALL_ROOT})
	if [ $? != 0 ]; then
		return 1
	fi

	# Extract new uris
	NEW_URIS=$(${OLD_TOOLS}/scripts/extract_rosinstall_uris.sh ${NEW_ROSINSTALL_OLD_ROOT})
	if [ $? != 0 ]; then
		return 1
	fi

	## declare an array variable
	declare -a TO_MOVE=()
	declare -a TO_REMOVE=()

	# For each OLD URI
	while read -r OLD_URI; do
	    # If old URI is in new .rosinstall
	    IS_IN="$(${OLD_TOOLS}/scripts/rosinstall_parser.sh ${NEW_ROSINSTALL_OLD_ROOT} contains_uri ${OLD_URI}; echo $?)"
	    
	    if [ "$IS_IN" == 1 ]; then
	    	echo "Error occurred, aborting!" | colorize RED
	    	return 1
	    fi

	    if [ "$IS_IN" == "100" ]; then
	    	OLD_PATH=${OLD_REPOS_ROOT}/$(${OLD_TOOLS}/scripts/rosinstall_parser.sh ${OLD_ROSINSTALL_ROOT} get_path_by_uri ${OLD_URI})
	    	NEW_PATH=${NEW_REPOS_ROOT}/$(${OLD_TOOLS}/scripts/rosinstall_parser.sh ${NEW_ROSINSTALL_OLD_ROOT} get_path_by_uri ${OLD_URI})
	    	echo "Old URI '${OLD_URI}' is also in new .rosinstall." | colorize BLUE
	    	if [ "${OLD_PATH}" == "${NEW_PATH}" ]; then 
	    		echo     " Equal, no action."  | colorize GREEN
	    	else
	    		TO_MOVE+=("${OLD_PATH},${NEW_PATH}")
	    		echo " Added to move list." | colorize YELLOW
	    		echo -en " Old: " | colorize BLUE
		    	echo     "${OLD_PATH}" | colorize YELLOW
		    	echo -en " New: " | colorize BLUE		
		    	echo     "${NEW_PATH}" | colorize YELLOW
	    	fi
	    else
	    	echo -en "Old URI '${OLD_URI}' is " | colorize BLUE
	    	echo -en "NOT " | colorize RED
	    	echo "in new .rosinstall." | colorize BLUE
	    	OLD_PATH=$(${OLD_TOOLS}/scripts/rosinstall_parser.sh ${OLD_ROSINSTALL_ROOT} get_path_by_uri ${OLD_URI})
	    	echo " Added to remove list." | colorize YELLOW
	    	echo -en " Path: " | colorize BLUE
	    	echo     "${OLD_PATH}" | colorize YELLOW
	    	TO_REMOVE+=("${OLD_REPOS_ROOT}/${OLD_PATH}")
	    fi
	done <<< "${OLD_URIS}"

	echo "All URI's compared, will now process moved and removed repositories." | colorize BLUE
	sleep 1

	for MOVE in "${TO_MOVE[@]}"
	do
		OLD_PATH=$(echo -e ${MOVE} | cut -d , -f 1)
		NEW_PATH=$(echo -e ${MOVE} | cut -d , -f 2)
		echo "Moving... " | colorize RED
    	echo -en " Old: " | colorize BLUE
    	echo     "${OLD_PATH}" | colorize YELLOW
    	echo -en " New: " | colorize BLUE		
    	echo     "${NEW_PATH}" | colorize YELLOW

    	# DO THE ACTUAL MOVING!
    	mkdir -p ${NEW_PATH}
    	mv -f ${OLD_PATH} ${NEW_PATH}/../

	done

	for REMOVE_PATH in "${TO_REMOVE[@]}"
	do
		echo -en "Removing '${REMOVE_PATH}'... " | colorize RED
		# DO THE ACTUAL REMOVING!
		rm -rf ${REMOVE_PATH}
		echo "done. " | colorize GREEN
	done

	# All new URI's added by the new deployment will be installed by git-update-all
	# ROSE TOOLS AND CONFIG HAVE ALSO BEEN MOVED FROM THIS POINT ON (IN CASE THE DIR CHANGED)
fi

# Store the old workspaces for clearing them later, before copying the rosinstall
OLD_WORKSPACES=$(${OLD_TOOLS}/scripts/extract_rosinstall_workspaces.sh ${OLD_ROSINSTALL_ROOT} | sort -u | uniq -u)

# In case the new repository root does not exist, create it
mkdir -p ${NEW_REPOS_ROOT}/
cd ${NEW_REPOS_ROOT}

# Copy the new .rosinstall to the repository root directory
echo -en "Copying new .rosinstall to the repository root... " | colorize BLUE
sleep 1
cp -f ${NEW_ROSINSTALL_OLD_ROOT}/.rosinstall  ${NEW_REPOS_ROOT}/
echo "done." | colorize GREEN

# Run wstool to install the new .rosinstall
source ${OLD_TOOLS}/scripts/wstool_retry_enabled.sh 50 ${NEW_REPOS_ROOT}
if [ $? != 0 ]; then
	return 1
fi

# Setup the environment, including ROS etc.
if [ -f ${OLD_TOOLS}/scripts/setup_environment.sh ]; then
    source ${OLD_TOOLS}/scripts/setup_environment.sh ${OLD_TOOLS}/scripts/source_deployment.sh ${NEW_DEPLOYMENT_FILE}
else
    echo "Could not find and run environment script '${OLD_TOOLS}/scripts/setup_environment.sh'." | colorize RED
    return 1
fi

# Update links to new deployment 
source "${ROSE_TOOLS}/scripts/link_deployment.sh"

# If we forced the OLD_CONFIG variable, remove it if the new ROSE_CONFIG path is different
if [ "${CONFIG_FORCED}" == true ] && [ "${OLD_CONFIG}" != "${ROSE_CONFIG}" ]; then
	echo "Removing old configuration folder '${OLD_CONFIG}'." | colorize RED
	rm -rf ${OLD_CONFIG}
fi
# If we forced the OLD_TOOLS variable, remove it if the new ROSE_TOOLS path is different
if [ "${TOOLS_FORCED}" == true ] && [ "${OLD_TOOLS}" != "${ROSE_TOOLS}" ]; then
	echo "Removing old tools folder '${OLD_TOOLS}'." | colorize RED
	rm -rf ${OLD_TOOLS}
fi

# UPDATE WORKSPACES
NEW_WORKSPACES=$(${ROSE_TOOLS}/scripts/extract_rosinstall_workspaces.sh ${ROSINSTALL_DIR} | sort -u | uniq -u)
echo "Creating new workspaces... " | colorize BLUE

# Create new workspaces file
echo -e "$NEW_WORKSPACES" > ${REPOS_ROOT}/.workspaces

# If we had an previous 'old' install, remove them old empty workspaces
if [ "${HAVE_OLD_REPOS_ROOT}" == true ]; then
	# Remove old empty workspaces
	echo "Removing old empty workspaces." | colorize BLUE
	sleep 1
	
	REMOVE_WORKSPACES=$(echo -e "${OLD_WORKSPACES}" | sort -u | uniq -u)

	# For each OLD URI
	while read -r WORKSPACE; do

		# Skip new workspaces
		if [ "$(echo -en ${NEW_WORKSPACES} | grep "${WORKSPACE}")" != "" ]; then
			continue
		fi

		pushd . > /dev/null 2>&1

		cd ${OLD_REPOS_ROOT}/${WORKSPACE}
		if [ $? != 0 ]; then
			continue
		fi
		FILES_WS=$(find . -maxdepth 1 -type f -printf '%f\n')

		cd src
		if [ $? != 0 ]; then
			continue
		fi
		NR_FILES_AND_DIRS_SRC=$(ls -A1 | wc -l)
		popd > /dev/null 2>&1

		if [ "${NR_FILES_AND_DIRS_SRC}" -gt "1" ]; then
			echo "Not removing workspace '${WORKSPACE}', because there are still ${NR_FILES_AND_DIRS_SRC} files/directories left in '${WORKSPACE}/src/." | colorize RED
		else
			if [ "${FILES_WS}" != "" ] && [ "${FILES_WS}" != ".catkin_workspace" ]; then
				echo "Not removing workspace '${WORKSPACE}', because there is not exactly only the '.catkin_workspace' file in '${WORKSPACE}/." | colorize RED
				echo ${FILES_WS}
			else
				echo -en "Removing workspace '${OLD_REPOS_ROOT}/${WORKSPACE}'... " | colorize RED
				rm -rf ${OLD_REPOS_ROOT}/${WORKSPACE}
				echo "done." | colorize GREEN
			fi
		fi
	done <<< "${REMOVE_WORKSPACES}"
fi

# Update the workspace build_order
echo "Updating workspaces build order..." | colorize BLUE
sleep 1
${ROSE_TOOLS}/scripts/update_workspace_build_order.sh
if [ $? == 0 ]; then
	echo "Done updating workspaces build order." | colorize GREEN
else
	return 1
fi

# Initialize workspaces if needed
${ROSE_TOOLS}/scripts/init_workspaces.sh

# Run first compile to compile the deployed code
echo "Running 'cm-clean all' to install the deployed code base." | colorize BLUE
cm-clean all
if [ $? != 0 ]; then
	return 1
fi

# Setup the environment once again
if [ -f /usr/bin/setup_environment.sh ]; then
    source /usr/bin/setup_environment.sh
else
    echo "Could not find and run environment script /usr/bin/setup_environment.sh: $(readlink /usr/bin/setup_environment.sh)." | colorize RED
    return 1
fi

cd ${ROSE_TOOLS}/scripts

echo -en "Successfully deployed: " | colorize BLUE
echo "$DEPLOYMENT_ID" 	| colorize GREEN
