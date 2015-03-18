#!/bin/bash

i="0"
nr_changed="0"
nr_unchanged="0"

echo "Checking repositories in currently installed rosinstall for changes." | colorize BLUE
echo "WARNING: This does not check for files which are untracked." | colorize YELLOW

nr_local_repos=$(wstool info --only=localname | grep -c "")

# Only if we have more than zero repositories
if [ $nr_local_repos -gt 0 ]; then
	local_repos=$(wstool info --only=localname)

	while [ $i -lt $nr_local_repos ]
	do
	  local_repo="$(echo -en "$local_repos" | sed -n $[$i+1]p)"
	  echo -en "Checking $local_repo -> "
	  changes=$(wstool status $local_repo)

	  if [ "$changes" == "" ]; then
	  	echo -e "unchanged" | colorize GREEN
	  	nr_unchanged=$[$nr_unchanged+1]
	  else
	  	echo -e "changed" | colorize RED
	  	echo -e "$changes"
	  	nr_changed=$[$nr_changed+1]
	  fi

	  i=$[$i+1]
	done
fi

echo -en "Found " | colorize BLUE
echo -en "$nr_unchanged " | colorize GREEN
echo -en "unchanged, and " | colorize BLUE
echo -en "$nr_changed " | colorize RED
echo -e "changed repositories." | colorize BLUE

if [ $nr_changed -gt 0 ]; then
	exit 1
else
	exit 0
fi
