#!/bin/bash

# Read arguments
ARG_1=$1
COMMAND=$2
ARG_2=$3


# Handy variables
CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

########## FUNCTIONS
function has_diff_names
{
	OUTPUT_1=$(${CURRENT_DIR}/extract_rosinstall_names.sh ${ARG_1})
	if [ $? != 0 ]; then
		exit 1
	fi

	OUTPUT_2=$(${CURRENT_DIR}/extract_rosinstall_names.sh ${ARG_2})
	if [ $? != 0 ]; then
		exit 1
	fi

	if [ "$OUTPUT_1" == "$OUTPUT_2" ]; then
		exit 100
	else
		exit 101
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

########## MAIN SCRIPT

# Arguments
#  diff_names: Compare rosinstalls names and check whether they are different, return 1 on error, return 100 on equal, 101 on not equal
#  compare_workspaces: Compare rosinstalls workspaces and check whether they are different, return 1 on error, return 100 on equal, 101 on not equal
#  compare_uris: Compare rosinstalls uris and check whether they are different, return 1 on error, return 100 on equal, 101 on not equal
case ${COMMAND} in
    "has_diff_names" )
        has_diff_names ;;
    "has_diff_workspaces" )
        has_diff_workspaces ;;
    "has_diff_uris" )
        has_diff_uris ;;
    "contains_uri" )
        contains_uri ;;
    * )
		echo "Invalid command '${COMMAND}' provided." | colorize RED
		exit 1
esac

exit 0
