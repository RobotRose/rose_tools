#!/bin/bash

# Wrapper for wstool update, adding retry unfinished repo's ability
# Press CTRL+C or wait for failure, to bring up retry menu
# Argument $1 specifies the number of parallel jobs to use
# Argument $2 specifies the workspace root

NR_PARALLEL=50
if [ "$1" ]
then
    NR_PARALLEL=$1
fi

WS_ROOT=${REPOS_ROOT}
if [ "$2" ]
then
    WS_ROOT=$2
fi

function run_wstool {
	COMMAND="wstool update ${RETRY_LIST} --target-workspace=${WS_ROOT} --parallel=${NR_PARALLEL}"
	echo "$COMMAND" | colorize BLUE
	stdbuf -oL -eL $COMMAND | tee >(grep "Done." | grep -oPi "\[.*\]" | grep -oPi "[(\w\/)]*" > $TEMP_FILE)
	if [ $? == 0 ]; then
		echo "wstool update success." | colorize GREEN
	else
		echo "wstool update failed." | colorize RED
		wstool_fail
	fi
}

function wstool_fail {
	killall wstool > /dev/null 2>&1
	ABORT=false
	SKIP=false
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
				Skip ) echo "Skipping wstool update!" | colorize RED; ABORT=true; SKIP=true; break;;
		        Abort ) echo "Aborting wstool update!" | colorize RED; ABORT=true; break;;
		    esac
		done	
	else
		echo "Do you want to retry all/retry single threaded/skip or abort?" | colorize BLUE
		select yn in "RetryAll" "RetrySingleThread" "Skip" "Abort" ; do
		    case $yn in
		        RetryAll ) RETRY_LIST=""; NR_PARALLEL=50; break;;
		        RetrySingleThread ) RETRY_LIST=""; NR_PARALLEL=1; break;;
				Skip ) echo "Skipping wstool update!" | colorize RED; ABORT=true; SKIP=true; break;;
		        Abort ) echo "Aborting wstool update!" | colorize RED; ABORT=true; break;;
		    esac
		done	
	fi

	if [ "$ABORT" == false ]; then
		run_wstool
	else
		trap - SIGINT
		if [ "$SKIP" == false ]; then
			return 1
		else
			return 0
		fi
	fi
}

trap 'wstool_fail' SIGINT

TEMP_FILE=$(mktemp) 

REPOS=$(wstool info --only=localname)

BASE_REPO_LIST=""
REPO_LIST=""
while read -r REPO; do
	BASE_REPO_LIST="$BASE_REPO_LIST $(basename $REPO)"
	REPO_LIST="$REPO_LIST $REPO"
done <<< "${REPOS}"

RETRY_LIST=${REPO_LIST}

run_wstool	

