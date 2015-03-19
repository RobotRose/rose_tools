#!/bin/bash

# This script uses wstool on a certain .rosinstall file in the provided directory and extracts the local paths, relative to the .rosinstall file
# Due to limitations of wstool (one cannot specify a file to be used as .rosinstall file) the file has to be named .rosinstall.
# This scripts cd's to that directory and runs wstool in that directory.

# Get first parameter
ROSINSTALL_ROOT=$1

pushd . > /dev/null 2>&1

# Check if a valid .rosinstall path has been provided.
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
${DIR}/contains_rosinstall.sh ${ROSINSTALL_ROOT}

if [ $? != 0 ]; then
	popd > /dev/null 2>&1; exit 1
fi

cd ${ROSINSTALL_ROOT}

# Read the paths
wstool info --only=localname

popd > /dev/null 2>&1
