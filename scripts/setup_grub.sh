#!/bin/bash  

DEFAULT_GRUB_CONFIG_FILE="$ROSE_TOOLS/scripts/default_grub_config"
GRUB_CONFIG_FILE="/etc/default/grub"

echo "Making backup of grub config file."

cp $GRUB_CONFIG_FILE ${GRUB_CONFIG_FILE}.bak

if [ $? -ne 0 ]; then
    echo "Error while making backup of config file, aborting grub configuration."
    exit 1
fi

echo "Copying grub config file."

cp $DEFAULT_GRUB_CONFIG_FILE $GRUB_CONFIG_FILE

if [ $? -ne 0 ]; then
    echo "Error while copying new config file, aborting grub configuration."
    exit 1
fi

echo "Applying grub config file."

update-grub

if [ $? -ne 0 ]; then
    echo "Error while apllying new config file, configuration failed."
    exit 1
else
    echo "Grub config succesfully installed."
fi

exit 0

