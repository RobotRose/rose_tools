#!/usr/bin/env bash

# For use from ROS machine files

echo "setup_env.sh: Running $(date)" > ~/setup_env.log

# Setup environment
if [ -f /usr/bin/setup_environment.sh ]; then
    source /usr/bin/setup_environment.sh
else
    echo "Could not find and run environment script /usr/bin/setup_environment.sh: $(readlink /usr/bin/setup_environment.sh)." >> ~/setup_env.log
    exit 1
fi

echo "setup_env.sh: Executing arguments: $@ " >> ~/setup_env.log
exec "$@"

echo "setup_env.sh: Done " >> ~/setup_env.log
