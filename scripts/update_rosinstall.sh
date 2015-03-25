#!/bin/bash

function resolve_conflict
{
	echo "There already is a .rosinstall file at ${REPOS_ROOT}." | colorize BLUE
	while : 
	do
		echo "'m' to merge (keeping existing extries)
      'n' to merge (replacing entries with new ones)
      'r' to replace 
      'k' to keep current rosinstall file
      'c' to cancel"
		read input
		case "$input" in
			'm' )
				wstool merge --merge-keep ${ROSINSTALL_FILE}
				break # from while loop
			;;
			'n' )
				wstool merge --merge-replace ${ROSINSTALL_FILE}
				break # from while loop
			;;
			'r' )
				echo "cp -f ${ROSINSTALL_FILE} ${REPOS_ROOT}/.rosinstall"
				cp -f ${ROSINSTALL_FILE} ${REPOS_ROOT}/.rosinstall 
				break # from while loop
			;;
			'k' )
				break # from while loop
			;;
			'c' )
				exit 1
			;;
			* )
				echo "Invalid command: '$input'" | colorize RED
			;;
		esac
	done
	
}

pushd . > /dev/null 2>&1

if [ ${ROSINSTALL_FILE} == "" ]; then
	echo "No .rosinstall file configured. Using default_rosinstall." | colorize BLUE
	ROSINSTALL_FILE=${ROSE_CONFIG}/rosinstall/default_rosinstall
fi

echo -n "REPOS_ROOT = " | colorize YELLOW
echo "${REPOS_ROOT}"
echo -n "ROSINSTALL_FILE = " | colorize YELLOW
echo "${ROSINSTALL_FILE}"

cd ${REPOS_ROOT}

if [ -f .rosinstall ]; then
	resolve_conflict
else
	echo "Creating new rosinstall file" | colorize BLUE
	wstool init .
	wstool merge ${ROSINSTALL_FILE}
fi

popd > /dev/null 2>&1
