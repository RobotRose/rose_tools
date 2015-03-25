#!/bin/bash

# Wrapper for wstool update, adding retry unfinished repo's ability
# Press CTRL+C or wait for failure, to bring up retry menu
# Argument $1 specifies the number of parallel jobs to use

NR_PARALLEL=50
if [ "$1" ]
then
    NR_PARALLEL=$1
fi

TEMP_FILE=$(mktemp) 

REPOS=$(wstool info --only=localname)

BASE_REPO_LIST=""
REPO_LIST=""
while read -r REPO; do
	BASE_REPO_LIST="$BASE_REPO_LIST $(basename $REPO)"
	REPO_LIST="$REPO_LIST $REPO"
done <<< "${REPOS}"

RETRY_WSTOOL=true
RETRY_LIST=${REPO_LIST}
while $RETRY_WSTOOL; do
	COMMAND="wstool update ${RETRY_LIST} --target-workspace=${REPOS_ROOT} --parallel=${NR_PARALLEL}"
	echo "$COMMAND" | colorize BLUE
	stdbuf -oL -eL $COMMAND | tee >(grep "Done." | grep -oPi "\[.*\]" | grep -oPi "[(\w\/)]*" > $TEMP_FILE)
		
	if [ $? == 0 ]; then
		echo "wstool update succeeded." | colorize GREEN
		RETRY_WSTOOL=false; break;
	else
		echo "wstool update failed." | colorize RED


		if [ -s $TEMP_FILE ]; then
			DONE="$(cat $TEMP_FILE)"

			RETRY_LIST=""
			BASE_RETRY_LIST=""
			BASE_FINISHED_LIST=""
			while read -r REPO; do
				ADD=true
				while read -r REPO_DONE; do
					if [ $REPO == $REPO_DONE ]; then
						ADD=false
					fi
				done <<< "${DONE}"

				if [ $ADD == true ]; then
					BASE_RETRY_LIST="$BASE_RETRY_LIST $(basename $REPO)"
					RETRY_LIST="$RETRY_LIST $REPO"
				else
					BASE_FINISHED_LIST="$BASE_FINISHED_LIST $(basename $REPO)"
				fi
			done <<< "${REPOS}"
		
			echo -en "Repositories finished: " | colorize BLUE
			echo "${BASE_FINISHED_LIST}" | colorize GREEN
			echo -en "Repositories not finished: " | colorize BLUE
			echo "${BASE_RETRY_LIST}" | colorize RED
			echo "Do you want to retry still active/retry all/retry single threaded/skip or abort?" | colorize BLUE
			select yn in "RetryUnfinished" "RetryAll" "RetrySingleThread" "Skip" "Abort" ; do
			    case $yn in
			    	RetryUnfinished ) echo "Retry: ${RETRY_LIST}" | colorize GREEN; break;;
			        RetryAll ) RETRY_LIST=""; NR_PARALLEL=50; break;;
			        RetrySingleThread ) RETRY_LIST=""; NR_PARALLEL=1; break;;
					Skip ) echo "Skipping wstool update!" | colorize RED; RETRY_WSTOOL=false; break;;
			        Abort ) echo "Aborting wstool update!" | colorize RED;RETRY_WSTOOL=false; return 1;;
			    esac
			done	
		else
			echo "Do you want to retry all/retry single threaded/skip or abort?" | colorize BLUE
			select yn in "RetryAll" "RetrySingleThread" "Skip" "Abort" ; do
			    case $yn in
			        RetryAll ) RETRY_LIST=""; NR_PARALLEL=50; break;;
			        RetrySingleThread ) RETRY_LIST=""; NR_PARALLEL=1; break;;
					Skip ) echo "Skipping wstool update!" | colorize RED; RETRY_WSTOOL=false; break;;
			        Abort ) echo "Aborting wstool update!" | colorize RED;RETRY_WSTOOL=false; return 1;;
			    esac
			done	
		fi
	fi
done
