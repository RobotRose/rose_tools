#!/bin/bash

# Read arguments
ARG_1=$1
COMMAND=$2
ARG_2=$3

# Handy variables
CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

########## FUNCTIONS
function has_diff_paths
{
	OUTPUT_1=$(${CURRENT_DIR}/extract_rosinstall_paths.sh ${ARG_1})
	if [ $? != 0 ]; then
		exit 1
	fi

	OUTPUT_2=$(${CURRENT_DIR}/extract_rosinstall_paths.sh ${ARG_2})
	if [ $? != 0 ]; then
		exit 1
	fi

	if [ "$OUTPUT_1" == "$OUTPUT_2" ]; then
		return 100
	else
		return 101
	fi
}

function has_diff_workspaces
{
	OUTPUT_1=$(${CURRENT_DIR}/extract_rosinstall_workspaces.sh ${ARG_1} | sort -u | uniq - u)
	if [ $? != 0 ]; then
		exit 1
	fi

	OUTPUT_2=$(${CURRENT_DIR}/extract_rosinstall_workspaces.sh ${ARG_2} | sort -u | uniq - u)
	if [ $? != 0 ]; then
		exit 1
	fi

	if [ "$OUTPUT_1" == "$OUTPUT_2" ]; then
		exit 100
	else
		exit 101
	fi
}

function has_diff_uris
{
	OUTPUT_1=$(${CURRENT_DIR}/extract_rosinstall_uris.sh ${ARG_1})
	if [ $? != 0 ]; then
		exit 1
	fi

	OUTPUT_2=$(${CURRENT_DIR}/extract_rosinstall_uris.sh ${ARG_2})
	if [ $? != 0 ]; then
		exit 1
	fi

	if [ "$OUTPUT_1" == "$OUTPUT_2" ]; then
		exit 100
	else
		exit 101
	fi
}

function contains_uri
{
	OUTPUT_1=$(${CURRENT_DIR}/extract_rosinstall_uris.sh ${ARG_1})
	if [ $? != 0 ]; then
		exit 1
	fi

	if [ $(echo -en \"${OUTPUT_1}\" | grep -c ${ARG_2}) != 0 ]; then
		exit 100
	else
		exit 101
	fi
}

function get_uri_by_path
{
	NAMES=$(${CURRENT_DIR}/extract_rosinstall_paths.sh ${ARG_1})
	if [ $? != 0 ]; then
		exit 1
	fi
	URIS=$(${CURRENT_DIR}/extract_rosinstall_uris.sh ${ARG_1})
	if [ $? != 0 ]; then
		exit 1
	fi

	# For each name check if it is the correct one
	let "i=1"
	while read -r NAME; do
		if [ "$NAME" == "$ARG_2" ]; then
			break;
		fi
		let "i++"
	done <<< "$NAMES"

	sed -n ${i}p <<< "$URIS"
}

function get_path_by_uri
{
	NAMES=$(${CURRENT_DIR}/extract_rosinstall_paths.sh ${ARG_1})
	if [ $? != 0 ]; then
		exit 1
	fi
	URIS=$(${CURRENT_DIR}/extract_rosinstall_uris.sh ${ARG_1})
	if [ $? != 0 ]; then
		exit 1
	fi

	# For each URI check if it is the correct one
	let "i=1"
	while read -r URI; do
		if [ "$URI" == "$ARG_2" ]; then
			break;
		fi
		let "i++"
	done <<< "$URIS"

	sed -n ${i}p <<< "$NAMES"
}

########## MAIN SCRIPT

# Arguments
#  has_diff_paths: Compare rosinstalls names and check whether they are different, return 1 on error, return 100 on equal, 101 on not equal
#  has_diff_workspaces: Compare rosinstalls workspaces and check whether they are different, return 1 on error, return 100 on equal, 101 on not equal
#  has_diff_uris: Compare rosinstalls uris and check whether they are different, return 1 on error, return 100 on equal, 101 on not equal
#  contains_uri: Check whether the rosinstall defined by ARG_1 contains the uri in ARG_2, return 1 on error, return 100 on true, 101 on false
case ${COMMAND} in
    "has_diff_paths" )
        has_diff_paths ;;
    "has_diff_workspaces" )
        has_diff_workspaces ;;
    "has_diff_uris" )
        has_diff_uris ;;
    "contains_uri" )
        contains_uri ;;
    "get_uri_by_path" )
		get_uri_by_path ;;
    "get_path_by_uri" )
		get_path_by_uri ;;
    * )
		echo "Invalid command '${COMMAND}' provided." | colorize RED
		exit 1
esac
