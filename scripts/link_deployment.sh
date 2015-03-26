#!/bin/bash

# Create link using currently source ROSE_TOOLS and ROSE_CONFIG paths, and ROBOT_INSTALLATION variable

# Create link to deployment file in /usr/bin/
DEPLOYMENT_FILE="${ROSE_CONFIG}/deployment/${ROBOT_INSTALLATION}/deployment.sh"
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
