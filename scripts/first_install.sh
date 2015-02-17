#!/bin/bash  

 # Check if we are sudo user
if [ "$(id -u)" != "0" ]; then
    echo -e "Sorry, you should run this script as root."
    exit 1
fi

ROSE_SCRIPTS_FOLDER_FILE="/usr/bin/set_rose_scripts_folder.sh"

# Get the path of this file
THIS_FOLDER=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

echo "Creating $SCRIPTS_FILE"
echo -en '#!/bin/bash\nROSE_SCRIPTS=' > $ROSE_SCRIPTS_FOLDER_FILE
echo -e "${THIS_FOLDER}" >> $ROSE_SCRIPTS_FOLDER_FILE

chmod +x $ROSE_SCRIPTS_FOLDER_FILE

source $ROSE_SCRIPTS_FOLDER_FILE

echo "Copying ${ROSE_SCRIPTS}/colorize to /usr/bin/"
cp ${ROSE_SCRIPTS}/colorize /usr/bin/colorize