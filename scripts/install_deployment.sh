#!/bin/bash

# Check if we are sudo user
if [ "$(id -u)" == "0" ]; then
    echo -e "Sorry, you should NOT run this script as root."
    return 1
fi

# Read arguments
DEPLOYMENT_ID=$1 		# Deployment ID as in current 'old' install
FORCE_ROSE_CONFIG=$2	# Full path ro rose_config package
FORCE_ROSE_TOOLS=$3		# Full path ro rose_config package

# Handy variables
CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

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
fi

if [ "$FORCE_ROSE_TOOLS" == "" ]; then
	OLD_TOOLS=${ROSE_TOOLS}
else
	OLD_TOOLS=${FORCE_ROSE_TOOLS}
fi

NEW_DEPLOYMENT_FILE="${OLD_CONFIG}/deployment/${DEPLOYMENT_ID}/deployment.sh"
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

# Source deployment file to read parameters
source ${NEW_DEPLOYMENT_FILE}

# Store new values
NEW_REPOS_ROOT=${HOME}/${REPOS_LOCATION}
NEW_ROSINSTALL_OLD_ROOT="${OLD_CONFIG}/rosinstall/${ROBOT_INSTALLATION}"

# Check if we now have a new repositories root
if [ ${NEW_REPOS_ROOT} == "" ]; then
	echo "No new repositories root detected." | colorize RED
	return 1
else
	echo -en "New repositories root is: " | colorize BLUE 
	echo "${NEW_REPOS_ROOT}" | colorize YELLOW
fi

# If we had an previous 'old' install, check difference
if [ HAVE_OLD_REPOS_ROOT ]; then

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
	    	TO_REMOVE+=("${OLD_PATH}")
	    fi
	done <<< "${OLD_URIS}"

	echo "All URI's compared, will now process moved and removed repositories." | colorize BLUE
	sleep 2

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
fi

# ROSE TOOLS AND CONFIG HAVE ALSO BEEN MOVED FROM THIS POINT ON (IF THEY HAD TO BE MOVED)

# Run source deployment script
NEW_TOOLS=${NEW_REPOS_ROOT}/deployment/src/rose_tools
source ${NEW_TOOLS}/scripts/source_deployment.sh ${NEW_DEPLOYMENT_FILE}
NEW_CONFIG=${ROSE_CONFIG}
NEW_ROSINSTALL_ROOT="${NEW_CONFIG}/rosinstall/${DEPLOYMENT_ID}"

# Copy the new .rosinstall to the repository root directory
echo -en "Copying new .rosinstall to the repository root... " | colorize BLUE
sleep 2
cp -f ${NEW_ROSINSTALL_OLD_ROOT}/.rosinstall  ${NEW_REPOS_ROOT}/
echo "done." | colorize GREEN

# Run git-update-all to install the new .rosinstall
# Thus also installing rose_tools and rose_config packages

RETRY_WSTOOL=true
NR_PARALLEL=50
while $RETRY_WSTOOL; do
	echo "Running 'wstool update' to install new .rosinstall... " | colorize BLUE
	sleep 2
	wstool update --target-workspace=${NEW_REPOS_ROOT} --parallel=${NR_PARALLEL}
	if [ $? == 0 ]; then
		RETRY_WSTOOL=false; break;
	else
		echo "wstool update failed." | colorize RED
		echo "Do you want to retry?"
		select yn in "Yes" "No" "Skip"; do
		    case $yn in
		        Yes ) break;;
		        No ) RETRY_WSTOOL=false; return 1;;
				Skip ) echo "Skipping wstool update!" | colorize RED; RETRY_WSTOOL=false; break;;
		    esac
		done	

	fi
done
echo "Done running 'wstool update'." | colorize GREEN


# UPDATE WORKSPACES

# If we had an previous 'old' install, olaso remove old empty workspaces
if [ HAVE_OLD_REPOS_ROOT ]; then
	# Remove old empty workspaces
	echo "Removing old empty workspaces." | colorize BLUE
	sleep 2
	OLD_WORKSPACES=$(${OLD_TOOLS}/scripts/extract_rosinstall_workspaces.sh ${OLD_ROSINSTALL_ROOT} | sort -u | uniq -u)
	NEW_WORKSPACES=$(${OLD_TOOLS}/scripts/extract_rosinstall_workspaces.sh ${NEW_ROSINSTALL_ROOT} | sort -u | uniq -u)
	REMOVE_WORKSPACES=$(echo -e "${OLD_WORKSPACES}\\n${NEW_WORKSPACES}" | sort -u | uniq -u)

	# For each OLD URI
	while read -r WORKSPACE; do
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

		if [ "${NR_FILES_AND_DIRS_SRC}" -gt "0" ]; then
			echo "Not removing old workspace '${WORKSPACE}', because there are still ${NR_FILES_AND_DIRS_SRC} files/directories left in '${WORKSPACE}/src/." | colorize RED
		else
			if [ ! "${FILES_WS}" == ".catkin_workspace" ]; then
				echo "Not removing old workspace '${WORKSPACE}', because there is not exactly only the '.catkin_workspace' file in '${WORKSPACE}/." | colorize RED
			else
				echo -en "Removing old workspace '${WORKSPACE}'... " | colorize RED
				# DO THE ACTUAL REMOVING
				echo "done." | colorize GREEN
			fi
		fi
	done <<< "${REMOVE_WORKSPACES}"
fi


echo "Creating new workspaces... " | colorize BLUE
# Create new workspaces file

echo -e "$NEW_WORKSPACES" > ${NEW_REPOS_ROOT}/.workspaces

# Initialize workspaces if needed
${ROSE_TOOLS}/scripts/init_workspaces.sh

# Update links to new deployment 
source "${ROSE_TOOLS}/scripts/link_deployment.sh"

# Force the environment to be setup with all new stuff installed
if [ -f /usr/bin/setup_environment.sh ]; then
    source /usr/bin/setup_environment.sh
else
    echo "Could not find and run environment script /usr/bin/setup_environment.sh: $(readlink /usr/bin/setup_environment.sh)." | colorize RED
fi

# Update the workspace build_order
echo "Updating workspaces build order..." | colorize BLUE
${ROSE_TOOLS}/scripts/update_workspace_build_order.sh
if [ $? == 0 ]; then
	echo "Done updating workspaces build order." | colorize GREEN
else
	return 1
fi

# Run first compile to compile the deployed code
echo "Running 'cm-clean all' to install the deployed code base." | colorize GREEN
cm-clean all

cd ${ROSE_TOOLS}/scripts
