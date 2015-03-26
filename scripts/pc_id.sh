#!/bin/bash

NEW_PC_ID=$1
FORCE=$2 			# provide an f as second argument to not ask if you want to set the id
PC_ID_FILE=${HOME}/.PC_ID

echo $1
echo $2

function export_pc_id {
	export PC_ID=$1
}

function set_pc_id {
	if [ "${1}" != "" ]; then
		echo ${1} > ${PC_ID_FILE}
		export_pc_id
	else
		echo "No id provided, not setting PC_ID."
		return 1
	fi	
}

# If an argument has been provided set the PC_ID file
if [ "${NEW_PC_ID}" != "" ]; then
	if [ "$FORCE" != "f" ]; then
		read -p "Are you sure you want to set the PC_ID to '${NEW_PC_ID}'? [y/n]: " -n 1 -r
		echo    # (optional) move to a new line
		if [[ $REPLY =~ ^[Yy]$ ]]
		then
		   	set_pc_id ${NEW_PC_ID}
		else
			echo "Not setting PC_ID."
			return 1
		fi
	else
		set_pc_id ${NEW_PC_ID}
	fi
fi

# Does the PC id-file exists
if [ -s ${PC_ID_FILE} ]; then
	# Read from file
	export_pc_id $(cat ${PC_ID_FILE})
	return 0
else
	# Ask the user
	read -p "Please provide the new PC_ID: " NEW_PC_ID
	set_pc_id ${NEW_PC_ID}
fi
