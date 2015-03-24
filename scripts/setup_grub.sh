#!/bin/bash  

DEFAULT_GRUB_CONFIG_FILE="$ROSE_TOOLS/scripts/default_grub_config"
GRUB_CONFIG_FILE="/etc/default/grub"

echo "Making backup of grub configuration file."

cp $GRUB_CONFIG_FILE ${GRUB_CONFIG_FILE}.bak

if [ $? -ne 0 ]; then
    echo "Error while making backup of configuration file, aborting grub configuration."
    exit 1
fi

echo "Copying grub configuration file."

cp $DEFAULT_GRUB_CONFIG_FILE $GRUB_CONFIG_FILE

if [ $? -ne 0 ]; then
    echo "Error while copying new configuration file, aborting grub configuration."
    exit 1
fi

echo "Applying grub configuration file."

update-grub

if [ $? -ne 0 ]; then
    echo "Error while applying new configuration file, configuration failed."
    exit 1
else
    echo "Grub configuration successfully installed."
fi

exit 0

