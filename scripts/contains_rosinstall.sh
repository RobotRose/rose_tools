#!/bin/bash

# Check if the provided directory (argument 1) contains a .rosinstall file.

# Get first parameter
ROSINSTALL_ROOT=$1

pushd . > /dev/null 2>&1

# Check if a valid .rosinstall path has been provided.
if [ "$ROSINSTALL_ROOT" == "" ]; then
	echo "No .rosinstall directory provided as first argument." | colorize RED
	popd > /dev/null 2>&1; exit 1
else
	cd $ROSINSTALL_ROOT
	if [ $? != 0 ]; then
		echo "Invalid .rosinstall directory '${ROSINSTALL_ROOT}' provided." | colorize RED
		popd > /dev/null 2>&1; exit 1
	fi

	if [ ! -f "${ROSINSTALL_ROOT}/.rosinstall" ]; then
		echo "No .rosinstall found in directory '${ROSINSTALL_ROOT}'." | colorize RED
		popd > /dev/null 2>&1; exit 1
	fi
fi

popd > /dev/null 2>&1
