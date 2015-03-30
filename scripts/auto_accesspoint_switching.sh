#!/bin/bash

# Scans for white-listed access points
# Switches provided wireless interface to the best available access point if:
# * There is an access point available to switch to.
# * The current access point 'signal strength' falls below a certain percentage of the 'average signal strength'.
# * The 'switch to' access point has a 'signal strength' which is a certain percentage better than the current AP 'signal strength'.
# * A minimal 'time between switching' has passed.


sudo ls  > /dev/null 2>&1
if [ $? != 0 ]; then
	echo "Need to be sudo user!" | colorize RED
	return 1
fi

WHITE_LIST_FILE=""
LOW_PERCENTAGE=""
BETTER_PERCENTAGE=""
MINIMAL_SWITCH_DELAY=""
DEFAULT_SSID="ROSE_WIFI"
while getopts ":w:l:h:d:i:" opt; do
  case $opt in
    w)	# complete path to white-listed access point SSID's file (each line a new SSID)
		echo "Using $OPTARG as white-listed access points SSID's file." >&2
		WHITE_LIST_FILE=$OPTARG
		;;
    l) 	# Switching low signal strength percentage numeric integer, without %
		case $OPTARG in
		    ''|*[!0-9]*) 
				echo "$OPTARG is not a valid low 'signal strength' percentage (valid is integer from 0 to 100, without %)." | colorize RED; 
				exit 1 
				;;
		    *)  ;;
		esac
		if [ "$OPTARG" -lt 0 ] && [ "$OPTARG" -gt 100 ]; then
			echo "$OPTARG is not a valid low 'signal strength' percentage (valid is integer from 0 to 100, without %)." | colorize RED; 
			exit 1 
		fi
		echo "Setting $OPTARG% as low 'signal strength' percentage." >&2
		LOW_PERCENTAGE=$OPTARG
		;;
    h)  # How much percent does the other AP need to be better than the current one before switching
		case $OPTARG in
		    ''|*[!0-9]*) 
				echo "$OPTARG is not a valid minimal improvement 'signal strength' percentage (valid is integer from 0 to 100, without %)." | colorize RED; 
				exit 1 
				;;
		    *)  ;;
		esac
		if [ "$OPTARG" -lt 0 ] && [ "$OPTARG" -gt 100 ]; then
			echo "$OPTARG is not a valid minimal improvement 'signal strength' percentage (valid is integer from 0 to 100, without %)." | colorize RED; 
			exit 1 
		fi
		echo "Setting $OPTARG% as minimal improvement 'signal strength' percentage." >&2		
		BETTER_PERCENTAGE=$OPTARG
		;;
	d)  # Minimal switching delay [seconds]
		case $OPTARG in
		    ''|*[!0-9]*) 
				echo "$OPTARG is not a valid switching delay." | colorize RED; 
				exit 1 
				;;
		    *)  ;;
		esac	
		echo "Setting $OPTARGs as minimal switching delay." >&2	
		MINIMAL_SWITCH_DELAY=$OPTARG
		;;
	i)	# Wireless Interface 
		echo "Using wireless interface $OPTARG." >&2	
		INTERFACE=$OPTARG
		;;
    \?)
		echo "Invalid option: -$OPTARG" >&2
		exit 1
		;;
    :)
		echo "Option -$OPTARG requires an argument." >&2
		exit 1
		;;
    *) 
		echo "Unimplemented option: -$OPTARG" >&2; 
		exit 1
		;;
  esac
done

### Functions ###
function parse_white_list_file
{
	WHITE_LIST=${WHITE_LIST_FILE}
}

function scan_access_points
{
	# $1 - interface
	# $2 - WHITE_LIST
	echo "scan_access_points: $2"
	echo "scan_access_points: sudo iwlist $1 scan | egrep -B 5 \"$2\""
	sudo iwlist $1 scan | egrep -B 5 \"$2\"
}

function get_list_size
{
	# $1 - \n LIST
	echo "$1" | wc -l
}

function is_valid_index
{
	# $1 \n LIST
	# $2 index
	echo "is_valid_index: $1 $2"
	if [ "$2" -lt 0 ] || [ "$2" -ge "$(get_list_size $1)" ]; then
		echo "Index $2 out of bounds, list:" | colorize RED
		echo -e $1
		echo false
	fi
	echo true
}

function get_AP_address
{
	# $1 - ACCESS_POINTS from scan
	# $2 - index
	if [ $(is_valid_index $1 $2) == true ]; then
		sed -n $2p <<< $(echo -en "$1" | grep 'Address:')
	else
		echo ""
	fi
}

function get_AP_DB
{
	# $1 - ACCESS_POINTS from scan
	# $2 - index
	return $1
}

### Main ###
if [ "$WHITE_LIST_FILE" == "" ]; then
	echo "No white-list file provided (-w), using '$DEFAULT_SSID' as default white-listed SSID." | colorize YELLOW
	WHITE_LIST="$DEFAULT_SSID"
else
	if [ ! -s $WHITE_LIST_FILE ]; then
		echo "Could not open white-list file '$WHITE_LIST_FILE'." | colorize RED
		exit 1
	else
		parse_white_list_file
	fi
fi

if [ "$INTERFACE" == "" ]; then
	echo "No interface provided (-i)." | colorize RED
	exit 1
fi

if [ "$LOW_PERCENTAGE" == "" ]; then
	echo "No low signal strength switch percentage provided (-l)." | colorize RED
	exit 1
fi

if [ "$BETTER_PERCENTAGE" == "" ]; then
	echo "No improvement signal strength switch percentage provided (-h)." | colorize RED
	exit 1
fi

if [ "$MINIMAL_SWITCH_DELAY" == "" ]; then
	echo "No minimal switch delay provided (-d), using default value of 10 seconds." | colorize YELLOW
	MINIMAL_SWITCH_DELAY=10
fi

ACCESS_POINTS=$(scan_access_points $INTERFACE $WHITE_LIST)
echo "ACCESS_POINTS"
echo "$ACCESS_POINTS"

ACCESS_POINTS_DB=$(get_AP_address $ACCESS_POINTS 1)

echo "ACCESS_POINTS_DB"
echo "$ACCESS_POINTS_DB"

