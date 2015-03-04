#!/bin/bash

PC_FROM=$1
ping -c 1 -i 1 $PC_FROM 1> /dev/null
if [ $? != 0 ]; then
	echo "First parameter must provide a valid, pingable, ip address of the PC you want to transfer from." | colorize RED
	exit 1
fi
PC_TO=$2
ping -c 1 -i 1 $PC_TO 1> /dev/null
if [ $? != 0 ]; then
	echo "Second parameter must provide a valid, pingable, ip address of the PC you want to transfer to." | colorize RED
	exit 1
fi
ROBOT_NAME=$3
if [ "$ROBOT_NAME" == "" ]; then
	echo "Third parameter must provide a valid robot name." | colorize RED
	exit 1
fi


echo "Transferring VPN configuration for '${ROBOT_NAME}' to $PC_TO from $PC_FROM..." | colorize GREEN
echo "This will overwrite configurations with the same name on the receiving PC!" | colorize YELLOW
sleep 1
echo "Please enter the username of $PC_FROM: " | colorize BLUE
read FROM_USERNAME
echo "Please enter the username of $PC_TO: " | colorize BLUE
read TO_USERNAME

CERTNAME="${TO_USERNAME}_${ROBOT_NAME}"
OPENVPN="/etc/openvpn/"
DIRECTORY_OPENVPN="/etc/openvpn/.vpn_client_${ROBOT_NAME}"
DIRECTORY_FROM="${DIRECTORY_OPENVPN}"
DIRECTORY_TO="/home/${TO_USERNAME}/.vpn_client_${ROBOT_NAME}"

echo "Checking existence of '${ROBOT_NAME}' its VPN configuration at $PC_FROM." | colorize BLUE
ssh $FROM_USERNAME@$PC_FROM test -d ${DIRECTORY_OPENVPN}
if [ $? != 0 ]; then
	echo "Directory ${DIRECTORY_OPENVPN} not found." | colorize RED
	exit 1
fi

echo "Certname: ${CERTNAME}"

echo "Preparing receiver $PC_TO." | colorize GREEN
ssh -t ${TO_USERNAME}@${PC_TO} "	sudo mkdir -v -p ${DIRECTORY_TO} && \
									sudo chown -v ${TO_USERNAME}:${TO_USERNAME} ${DIRECTORY_TO} && \
									sudo chmod -v 777 ${DIRECTORY_TO}/ && \
									sudo mkdir -v -p ${DIRECTORY_OPENVPN}"
if [ $? == 1 ]; then
	echo "Unable to create receiving directory at $PC_TO." | colorize RED
	exit 1
fi

echo "Preparing \"sudo ${ROSE_TOOLS}/scripts/setup_vpn_client.sh ${TO_USERNAME} ${ROBOT_NAME} ${PC_FROM}\"" | colorize GREEN
ssh -t ${FROM_USERNAME}@${PC_FROM} "	source /usr/bin/robot_file.sh && \
										sudo \${ROSE_TOOLS}/scripts/setup_vpn_client.sh ${TO_USERNAME} ${ROBOT_NAME} ${PC_FROM}"

if [ $? == 1 ]; then
	echo "Unable to create vpn configuration for $PC_TO at $PC_FROM." | colorize RED
	exit 1
fi

echo "Sending VPN config from $PC_FROM to $PC_TO." | colorize GREEN
ssh -t ${FROM_USERNAME}@${PC_FROM} "	sudo chown -v ${FROM_USERNAME}:${FROM_USERNAME} ${DIRECTORY_FROM} && \
										sudo chown -v ${FROM_USERNAME}:${FROM_USERNAME} ${DIRECTORY_FROM}/* && \
										sudo chmod -v 777 ${DIRECTORY_FROM}/ ${DIRECTORY_FROM}/* && \
										scp ${DIRECTORY_FROM}/${CERTNAME}.* ${DIRECTORY_FROM}/vpn_client_${CERTNAME}.conf ${DIRECTORY_FROM}/ca.crt ${TO_USERNAME}@${PC_TO}:${DIRECTORY_TO} && \
										sudo chown -v root:root ${DIRECTORY_FROM}/ ${DIRECTORY_FROM}/* && \
										sudo chmod -v 644 ${DIRECTORY_FROM}/ ${DIRECTORY_FROM}/*"
if [ $? == 1 ]; then
	echo "Unable to copy VPN config from $PC_FROM to receiving directory at $PC_TO." | colorize RED
	exit 1
fi

echo "Finalizing configuration at $PC_TO." | colorize GREEN
ssh -t ${TO_USERNAME}@${PC_TO} "	sudo rm -rf ${DIRECTORY_OPENVPN} && \
									sudo mv -f -v ${DIRECTORY_TO}/ ${OPENVPN}/ && \
									sudo chown -v root:root ${DIRECTORY_OPENVPN} ${DIRECTORY_OPENVPN}/* && \
									sudo chmod -v 644 ${DIRECTORY_OPENVPN}/*"
if [ $? == 1 ]; then
	echo "Unable to move files to /etc/openvpn/ at $PC_TO." | colorize RED
	exit 1
fi

echo "Done copying configuration, have a nice day." | colorize GREEN

