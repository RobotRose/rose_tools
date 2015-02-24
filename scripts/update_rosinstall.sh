#!/bin/bash

resolve_conflict () 
{
	echo "There already is a .rosinstall file at $ROSINSTALL_ROOT." | colorize BLUE
	while : 
	do
		echo "Press 'm' to merge (keeping existing extries)
      'n' to merge (replacing entries with new ones)
      'r' to replace 
      'k' to keep current rosinstall file
      'c' to cancel"
		read input
		case "$input" in
			'm' )
				wstool merge --merge-keep $ROSINSTALL_FILE
				break # from while loop
			;;
			'n' )
				wstool merge --merge-replace $ROSINSTALL_FILE
				break # from while loop
			;;
			'r' )
				rm .rosinstall
				wstool init .
				wstool merge $ROSINSTALL_FILE
				break # from while loop
			;;
			'k' )
				break # from while loop
			;;
			'q' )
				exit 1
			;;
			* )
				echo "Invalid command: '$input'" | colorize RED
			;;
		esac
	done
	
}

pushd .

if [[ $ROSINSTALL_CONFIG == '' ]]; then
	echo "No rosinstall file configured in $ROBOT_FILE. Using default_rosinstall." | colorize BLUE
	ROSINSTALL_FILE=${ROSE_CONFIG}/rosinstall/default_rosinstall
else
	ROSINSTALL_FILE=${ROSINSTALL_CONFIG}
fi

echo -n "ROSINSTALL_FILE = " | colorize YELLOW
echo "$ROSINSTALL_FILE"
echo -n "ROSINSTALL_ROOT = " | colorize YELLOW
echo "$ROSINSTALL_ROOT"

cd $ROSINSTALL_ROOT

if [ -f .rosinstall ]; then
	resolve_conflict
else
	echo "Creating new rosinstall file" | colorize BLUE
	wstool init .
	wstool merge $ROSINSTALL_FILE
fi

popd
