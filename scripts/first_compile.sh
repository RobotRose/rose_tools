#!/bin/bash  

pushd . > /dev/null 2>&1

 # Check if we are sudo user
if [ "$(id -u)" == "0" ]; then
    echo -e "Sorry, you should NOT run this script as root."
    return 1
fi

echo "Installing the Rose B.V. software."

# Turn on git credentials cache
git config --global credential.helper cache

cd ${FIRST_COMPILE_ROOT}
rm -rf rose_config
git clone https://github.com/RobotRose/rose_config.git -b requirement/1207_platform_params_configurable

echo "Copying the default bashrc to ~/.bashrc"
cp ${FIRST_COMPILE_ROOT}/rose_tools/scripts/default_bashrc ~/.bashrc
echo "Done. "

read -p "Please provide the deployment id: " DEPLOYMENT_ID
cd rose_tools/scripts/
source install_deployment.sh ${DEPLOYMENT_ID} ${FIRST_COMPILE_ROOT}/rose_config/rose_config ${FIRST_COMPILE_ROOT}/rose_tools

popd > /dev/null 2>&1
