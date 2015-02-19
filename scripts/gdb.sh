#!/bin/bash  
# #!/usr/bin/env bash

source $ROSE_TOOLS/scripts/setup_ROS.sh "/opt/ros/hydro/" "localhost" "http://localhost:11311"
gdb -interpreter=mi $1

