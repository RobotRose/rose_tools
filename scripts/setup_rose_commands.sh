#!/bin/bash  
# This script sets up commands for the user rose that might be used without sudo rights

echo "Adding standard sudo commands for Rose" | colorize BLUE

 # Check if we are sudo user
if [ "$(id -u)" != "0" ]; then
    echo -e "Sorry, you are not root, run with sudo." | colorize RED
    exit 1
fi

echo "user_name ALL=(ALL) NOPASSWD: /sbin/poweroff, /sbin/reboot, /sbin/shutdown" >> /etc/sudoers

echo "Done!" | colorize GREEN