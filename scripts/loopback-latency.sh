#!/bin/bash
#   tc -s qdisc show dev lo
#   tc -p filter show dev lo
# $1 which interface
# $2 "clear" -> clear rules
# $2 -> delay in ms
# $3 -> packetloss in %
# $4 -> stddev in ms
# $5 -> stddev percentage in %, percentage change that delay will vary with +-STDDEV

if [ "$1" == "" -o "$1" == "clear" ]; then
	echo "First parameter must specify the interface, for example 'lo' or 'eth1'."
	exit 1
fi

DEV=$1

if [ "$2" == "" ]; then
	echo "Second parameter needs to be either 'clear' or the amount of delay in ms."
	exit 1
fi

ACTIVE=$(tc qdisc show dev $DEV | grep netem)
if [ "$2" == "clear" ]; then
	if [ "$ACTIVE" != "" ]; then
		tc qdisc del dev $DEV root
		echo "Cleared rules on interface $DEV."
	else
		echo "Nothing to clear on interface $DEV."
	fi
else
	
	if [ "$ACTIVE" != "" ]; then
		tc qdisc del dev $DEV root
	fi
	
	DELAY=${2}msec
	
	if [ "$3" == "" ]; then
		echo "Third parameter not provided, it sets the amount of packetloss as a percentage, using default 0% packetloss."
		PACKETLOSS=0%
	else
		PACKETLOSS=${3}%
	fi

	if [ "$4" == "" ]; then
		echo "Fourth parameter not provided, it sets the std dev on the delay, using default 10ms."
		STDDEV=10msec
	else
		STDDEV=${4}msec
	fi
	if [ "$5" == "" ]; then
		echo "Fifth parameter not provided, it sets the std dev percentage, using default 25%."
		STDDEVPERCENTAGE=25%
	else
		STDDEVPERCENTAGE=${5}%
	fi	
	
	# Create a priority-based queue.
	tc qdisc add dev $DEV root handle 1:0 netem delay $DELAY $STDDEV $STDDEVPERCENTAGE loss $PACKETLOSS
	
	# Check if succesfull
	if [ $? -eq 0 ]; then
		echo "Succesfully set rule."
	else
		echo "Error setting rule."
		exit 1
	fi
fi

exit 0

