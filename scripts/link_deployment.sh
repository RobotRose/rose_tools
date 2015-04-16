#!/bin/bash

# Create link using currently source ROSE_TOOLS and ROSE_CONFIG paths, and ROBOT_INSTALLATION variable

# Check if we are sudo user
if [ "$(id -u)" == "0" ]; then
    echo -e "Sorry, you should NOT run this script as root." | colorize RED
    exit 1
fi

# Create link to deployment file in /usr/bin/
DEPLOYMENT_FILE="${ROSE_CONFIG}/deployment/${ROBOT_DEPLOYMENT}/deployment.sh"
DEPLOYMENT_FILE_LINKNAME="/usr/bin/deployment_file.sh"

echo "Linking deployment file: '${DEPLOYMENT_FILE_LINKNAME}' to '${DEPLOYMENT_FILE}'... " | colorize BLUE

sudo ln -s -f $DEPLOYMENT_FILE $DEPLOYMENT_FILE_LINKNAME
if [ $? -eq 1 ]; then    
    echo "Failed linking." | colorize RED
    echo "Could not symlink '${DEPLOYMENT_FILE_LINKNAME}' to '${DEPLOYMENT_FILE}'."
    return 1
fi
echo "Done linking deployment file." | colorize GREEN

# Create link to deployment script in /usr/bin/
DEPLOYMENT_SCRIPT="${ROSE_TOOLS}/scripts/source_deployment.sh"
DEPLOYMENT_SCRIPT_LINKNAME="/usr/bin/deployment_script.sh"

echo "Linking deployment script: '${DEPLOYMENT_SCRIPT_LINKNAME}' to '${DEPLOYMENT_SCRIPT}'... " | colorize BLUE

sudo ln -s -f $DEPLOYMENT_SCRIPT $DEPLOYMENT_SCRIPT_LINKNAME
if [ $? -eq 1 ]; then    
    echo "Failed linking." | colorize RED
    echo "Could not symlink '${DEPLOYMENT_SCRIPT_LINKNAME}' to '${DEPLOYMENT_SCRIPT}'."
    return 1
fi
echo "Done linking deployment script." | colorize GREEN

# Create link to environment script in /usr/bin/
ENVIRONMENT_SCRIPT="${ROSE_TOOLS}/scripts/setup_environment.sh"
ENVIRONMENT_SCRIPT_LINKNAME="/usr/bin/setup_environment.sh"

echo "Linking environment script: '${ENVIRONMENT_SCRIPT_LINKNAME}' to '${ENVIRONMENT_SCRIPT}'... " | colorize BLUE

sudo ln -s -f $ENVIRONMENT_SCRIPT $ENVIRONMENT_SCRIPT_LINKNAME
if [ $? -eq 1 ]; then    
    echo "Failed linking." | colorize RED
    echo "Could not symlink '${ENVIRONMENT_SCRIPT_LINKNAME}' to '${ENVIRONMENT_SCRIPT}'."
    return 1
fi
echo "Done linking environment script." | colorize GREEN

# Create link to machine environment script in /usr/bin/
MACHINE_ENVIRONMENT_SCRIPT="${ROSE_TOOLS}/scripts/setup_machine_env.sh"
MACHINE_ENVIRONMENT_SCRIPT_LINKNAME="/usr/bin/setup_machine_env.sh"

echo "Linking machine enviroment script: '${MACHINE_ENVIRONMENT_SCRIPT_LINKNAME}' to '${MACHINE_ENVIRONMENT_SCRIPT}'... " | colorize BLUE

sudo ln -s -f $MACHINE_ENVIRONMENT_SCRIPT $MACHINE_ENVIRONMENT_SCRIPT_LINKNAME
if [ $? -eq 1 ]; then    
    echo "Failed linking." | colorize RED
    echo "Could not symlink '${MACHINE_ENVIRONMENT_SCRIPT_LINKNAME}' to '${MACHINE_ENVIRONMENT_SCRIPT}'."
    return 1
fi
echo "Done linking environment script." | colorize GREEN


# Create link to auto_accesspoint_switching.py script in /usr/bin/
AP_SWITCHING_SCRIPT="${ROSE_TOOLS}/scripts/auto_accesspoint_switching.py"
AP_SWITCHING_SCRIPT_LINKNAME="/usr/bin/auto_accesspoint_switching.py"

echo "Linking auto_accesspoint_switching.py script: '${AP_SWITCHING_SCRIPT_LINKNAME}' to '${AP_SWITCHING_SCRIPT}'... " | colorize BLUE

sudo ln -s -f $AP_SWITCHING_SCRIPT $AP_SWITCHING_SCRIPT_LINKNAME
if [ $? -eq 1 ]; then    
    echo "Failed linking." | colorize RED
    echo "Could not symlink '${AP_SWITCHING_SCRIPT_LINKNAME}' to '${AP_SWITCHING_SCRIPT}'."
    return 1
fi
echo "Done linking auto_accesspoint_switching.py script." | colorize GREEN

# Create link to boot_rose.py script in /usr/bin/
BOOT_ROSE="${ROSE_TOOLS}/scripts/boot_rose.py"
BOOT_ROSE_LINKNAME="/usr/bin/boot_rose.py"

echo "Linking boot_rose.py script: '${BOOT_ROSE_LINKNAME}' to '${BOOT_ROSE}'... " | colorize BLUE

sudo ln -s -f $BOOT_ROSE $BOOT_ROSE_LINKNAME
if [ $? -eq 1 ]; then    
    echo "Failed linking." | colorize RED
    echo "Could not symlink '${BOOT_ROSE_LINKNAME}' to '${BOOT_ROSE}'."
    return 1
fi
echo "Done linking boot_rose.py script." | colorize GREEN
