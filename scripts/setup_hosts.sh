#!/bin/bash  

HOSTSFILE="/etc/hosts"

ROSEPC1_IP="10.8.0.1        rosepc1"
ROSEPC2_IP="10.8.0.2        rosepc2"
ROSEREMOTE_IP="10.8.0.3        rosepcremote"

# get line number and replace 
FIND="rosepc1"
N=$(cat /etc/hosts | grep -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\s*$FIND" -n | grep -Po ".*?(?=:)")

# Append or overwrite?
if [ "$N" == "" ]; then
    echo "Appending $ROSEPC1_IP."
    echo $ROSEPC1_IP >> $HOSTSFILE
else
    echo "Overwriting $ROSEPC1_IP."
    sed -i "${N}s/.*/$ROSEPC1_IP/" $HOSTSFILE
fi

# get line number and replace 
FIND="rosepc2"
N=$(cat /etc/hosts | grep -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\s*${FIND}" -n | grep -Po ".*?(?=:)")

# Append or overwrite?
if [ "$N" == "" ]; then
    echo "Appending $ROSEPC2_IP."
    echo $ROSEPC2_IP >> $HOSTSFILE
else
    echo "Overwriting $ROSEPC2_IP."
    sed -i "${N}s/.*/$ROSEPC2_IP/" $HOSTSFILE
fi


# get line number and replace 
FIND="rosepcremote"
N=$(cat /etc/hosts | grep -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\s*${FIND}" -n | grep -Po ".*?(?=:)")

# Append or overwrite?
if [ "$N" == "" ]; then
    echo "Appending $ROSEREMOTE_IP."
    echo $ROSEREMOTE_IP >> $HOSTSFILE
else
    echo "Overwriting $ROSEREMOTE_IP."
    sed -i "${N}s/.*/$ROSEREMOTE_IP/" $HOSTSFILE
fi

