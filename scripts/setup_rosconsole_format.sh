#!/bin/bash

echo -en "Setting rosconsole format... "  | colorize BLUE
export ROSCONSOLE_FORMAT='${time}|${logger}[${severity}]: ${message}' 
echo "done."  | colorize GREEN
