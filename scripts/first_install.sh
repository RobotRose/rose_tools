#!/bin/bash  

 # Check if we are sudo user
if [ "$(id -u)" != "0" ]; then
    echo -e "Sorry, you should run this script as root."
    exit 1
fi

FILE="/usr/bin/set_rose_scripts_folder.sh"

# Get the path of this file
THIS_FOLDER=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

echo "Creating $FILE"
echo -en '#!/bin/bash\nROSE_SCRIPTS=' > $FILE
echo -e "${THIS_FOLDER}" >> $FILE

chmod +x $FILE

source $FILE

echo "Copying ${ROSE_SCRIPTS}/colorize to /usr/bin/"
cp ${ROSE_SCRIPTS}/colorize /usr/bin/colorize
