#!/bin/bash  

KEYS="/etc/openvpn/easy-rsa/keys"
OPENVPN="/etc/openvpn"
EASYRSA="$OPENVPN/easy-rsa"

# Setup the vars in robot_file.sh by sourcing the symlinked file in /usr/bin.
# This file is installed by running the first_install.sh script
source robot_file.sh

SSH_RSA_SCRIPT="${ROSE_TOOLS}/scripts/setup_SSHRSA.sh"
DEFAULT_RSA_VARS="${ROSE_TOOLS}/scripts/default_easyrsa_vars"
DEFAULT_CLIENT_CONF="${ROSE_TOOLS}/scripts/default_client_vpn.conf"
DEFAULT_SERVER_CONF="${ROSE_TOOLS}/scripts/default_server_vpn.conf"

# Get and check commandline parameters
CLIENT_NAME=$1
ROBOT_NAME=$2
SERVER_IP=$3


if [ "$CLIENT_NAME" == "" ]; then
	echo "First argument must provide the name of the client." | colorize BLUE
fi

if [ "$ROBOT_NAME" == "" ]; then
	echo "Second argument must provide the name of the robot." | colorize BLUE
fi

echo "Creating certificate of robot ${ROBOT_NAME} with server ip ${SERVER_IP},for client ${CLIENT_NAME}" | colorize GREEN

CERT_NAME="${CLIENT_NAME}_${ROBOT_NAME}"
REMOTE_CLIENT_DIR="${OPENVPN}/.vpn_client_${ROBOT_NAME}"
REMOTE_CLIENT_CONF_NAME="vpn_client_${CERT_NAME}.conf"
REMOTE_CLIENT_CONF_PATH="${REMOTE_CLIENT_DIR}/${REMOTE_CLIENT_CONF_NAME}"

echo "Creating certificate for client ${CLIENT_NAME}: ${CERT_NAME}" | colorize BLUE
cd $OPENVPN

# Copy the default vars script
cp -f -v ${ROSE_TOOLS}/scripts/default_easyrsa_vars $EASYRSA/vars

# Add client specific information to the vars
echo "export KEY_COUNTRY=\"NL\" 		\n \
export KEY_PROVINCE=\"NB\" 				\n \
export KEY_CITY=\"Eindhoven\" 			\n \
export KEY_ORG=\"Rose-BV\" 				\n \
export KEY_EMAIL=\"info@robot-rose.nl\"	\n \
export KEY_NAME=${CERT_NAME} 			\n \
export KEY_OU=RoseVPN 					\n \
export PKCS11_MODULE_PATH=changeme		\n \
export PKCS11_PIN=1234" 						>> $EASYRSA/vars

# Source them
source $EASYRSA/vars

# Create the certificate
$EASYRSA/pkitool ${CERT_NAME}

if [ $? != 0 ]; then
    echo "Error creating certificate ${CERT_NAME}, stopping." | colorize RED
    exit 1
fi

# Copy config to folder in openvpn directory
mkdir -p $REMOTE_CLIENT_DIR
echo ""
echo "Copying certificate, key and config files of ${CERT_NAME} to ${REMOTE_CLIENT_DIR}/" | colorize BLUE
cp -v -f ${KEYS}/${CERT_NAME}.crt ${KEYS}/${CERT_NAME}.key ${KEYS}/ca.crt ${KEYS}/ta.key ${REMOTE_CLIENT_DIR}
cp -v -f ${DEFAULT_CLIENT_CONF} ${REMOTE_CLIENT_CONF_PATH}
echo "remote $SERVER_IP 1194" >> ${REMOTE_CLIENT_CONF_PATH}
echo "ca ${OPENVPN}/.vpn_client_${ROBOT_NAME}/ca.crt" >> ${REMOTE_CLIENT_CONF_PATH}
echo "cert ${OPENVPN}/.vpn_client_${ROBOT_NAME}/${CERT_NAME}.crt" >> ${REMOTE_CLIENT_CONF_PATH} 
echo "key ${OPENVPN}/.vpn_client_${ROBOT_NAME}/${CERT_NAME}.key" >> ${REMOTE_CLIENT_CONF_PATH}

echo "Done" | colorize GREEN
exit 0

