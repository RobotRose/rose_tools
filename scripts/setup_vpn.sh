#!/bin/bash  

KEYS="/etc/openvpn/easy-rsa/keys"
OPENVPN="/etc/openvpn"
EASYRSA="$OPENVPN/easy-rsa"

# Setup the vars in robot_file.sh by sourcing the symlinked file in /usr/bin.
# This file is installed by running the first_install.sh script
source robot_file.sh

SSH_RSA_SCRIPT="$ROSE_TOOLS/scripts/setup_SSHRSA.sh"
DEFAULT_RSA_VARS="$ROSE_TOOLS/scripts/default_easyrsa_vars"
DEFAULT_CLIENT_CONF="$ROSE_TOOLS/scripts/default_client_vpn.conf"
DEFAULT_SERVER_CONF="$ROSE_TOOLS/scripts/default_server_vpn.conf"
SCP_PASSWORD="rose"
ROSEPC2_IP="192.168.0.102"
ROSEPC2_KEYS="/home/rose/.keys"

# To be sure we have colorize in the PATH
export PATH="$ROSE_TOOLS/scripts:$PATH"

echo "Setting up vpn..." | colorize BLUE

ROBOT_NAME=$1
SERVER_IP=$(echo $2 | grep -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}")
SERVER_IP_ROSEPC2="192.168.0.101"

if [ "$ROBOT_NAME" == "" ]; then
    echo "First argument must specify the robot's name." | colorize RED
    exit 1
else
    echo "The robot name will be: $ROBOT_NAME" | colorize GREEN
fi

if [ "$SERVER_IP" == "" ]; then
    echo "Second argument must specify the server public (or LAN) IP." | colorize RED
    exit 1
else
    
    echo "Server IP will be: $SERVER_IP" | colorize GREEN
fi


echo "Checking connection to rosepc2.." | colorize BLUE
ping -c 1 -i 1 $ROSEPC2_IP 2>&1 1> /dev/null

if [ $? != 0 ]; then
    echo "Make sure rosepc2 is turned on and connected at connected at $ROSEPC2_IP" | colorize RED
    exit 1
else
    echo "Connection to rosepc2 ($ROSEPC2_IP) established." | colorize GREEN
fi

echo "Setting up hosts." | colorize BLUE
./setup_hosts.sh

if [ $? != 0 ]; then
    echo "Could not setup hosts file."
    exit 1
fi


# sudo rm -rf $EASYRSA
mkdir -p $EASYRSA

if [ $? != 0 ]; then
    echo "Error creating directory, stopping." | colorize RED
    exit 1
fi

echo "Copying easy-rsa" | colorize BLUE
cp -r /usr/share/doc/openvpn/examples/easy-rsa/2.0/* $EASYRSA

if [ $? != 0 ]; then
    echo "Error copying easy-rsa directory, stopping." | colorize RED
    exit 1
fi

echo "Copying default vars file." | colorize BLUE
cp $DEFAULT_RSA_VARS $EASYRSA/vars

if [ $? != 0 ]; then
    echo "Error copying easy-rsa vars, stopping." | colorize RED
    exit 1
fi

# Add server specific information to the vars
echo "export KEY_COUNTRY=\"NL\"         \n \
export KEY_PROVINCE=\"NB\"              \n \
export KEY_CITY=\"Eindhoven\"           \n \
export KEY_ORG=\"Rose-BV\"              \n \
export KEY_EMAIL=\"info@robot-rose.nl\" \n \
export KEY_NAME=${ROBOT_NAME}_VPN_server \n \
export KEY_OU=RoseVPN                   \n \
export PKCS11_MODULE_PATH=changeme      \n \
export PKCS11_PIN=1234"                     >> $EASYRSA/vars

echo "Running server generation scripts." | colorize BLUE

source $EASYRSA/vars

$EASYRSA/clean-all
if [ $? != 0 ]; then
    echo "Error while running 'clean-all', stopping." | colorize RED
    exit 1
fi
$EASYRSA/build-dh
if [ $? != 0 ]; then
    echo "Error while running 'build-dh', stopping." | colorize RED
    exit 1
fi
$EASYRSA/pkitool --initca 
if [ $? != 0 ]; then
    echo "Error while running 'pkitool --initca', stopping." | colorize RED
    exit 1
fi
$EASYRSA/pkitool --server "server_${ROBOT_NAME}"
if [ $? != 0 ]; then
    echo "Error while running 'pkitool --server server_$ROBOT_NAME', stopping." | colorize RED
    exit 1
fi

openvpn --genkey --secret "$KEYS/ta.key"

if [ $? != 0 ]; then
    echo "Error while running 'openvpn --genkey --secret ta.key', stopping." | colorize RED
    exit 1
fi

echo "Copying server config file from default." | colorize BLUE
SERVERCONFIG="${OPENVPN}/server_${ROBOT_NAME}.conf"
cp $DEFAULT_SERVER_CONF $SERVERCONFIG
echo "ca ca.crt" >> $SERVERCONFIG
echo "cert server_${ROBOT_NAME}.crt" >> $SERVERCONFIG
echo "key server_${ROBOT_NAME}.key   # This file should be kept secret" >> $SERVERCONFIG
#echo "tls-auth ta.key 0" >> $SERVERCONFIG

if [ $? != 0 ]; then
    echo "Could not copy default server config file." | colorize RED
    exit 1
fi

cp $KEYS/server_${ROBOT_NAME}.crt $KEYS/server_${ROBOT_NAME}.key $KEYS/ca.crt $KEYS/dh1024.pem $KEYS/ta.key $OPENVPN

if [ $? != 0 ]; then
    echo "Error copying certificate, stopping." | colorize RED
    exit 1
fi

CLIENT_NAME="rosepc2"
CERT_NAME="${CLIENT_NAME}_${ROBOT_NAME}"
REMOTECLIENT_DIR="${OPENVPN}/.vpn_client_${ROBOT_NAME}"
REMOTECLIENT_CONF_NAME="vpn_client_${CERT_NAME}.conf"
REMOTECLIENT_CONF_PATH="${REMOTECLIENT_DIR}/${REMOTECLIENT_CONF_NAME}"

sudo ./setup_vpn_client.sh rosepc2 ${ROBOT_NAME} ${SERVER_IP}

if [ $? != 0 ]; then
    echo "Error creating certificates for rosepc2, stopping." | colorize RED
    exit 1
fi

echo "Copying certificates to ${CLIENT_NAME}." | colorize BLUE

expect -c " 
   exp_internal 0
   set timeout 60
   spawn rsync -Ive ssh ${REMOTECLIENT_DIR}/${CERT_NAME}.crt ${REMOTECLIENT_DIR}/${CERT_NAME}.key ${REMOTECLIENT_DIR}/ca.crt ${REMOTECLIENT_DIR}/ta.key ${REMOTECLIENT_CONF_PATH} rose@${ROSEPC2_IP}:${ROSEPC2_KEYS}/
   expect {
      \"yes/no\" { send yes\n; exp_continue }
      \"password:\" { send $SCP_PASSWORD\n }
      timeout { send_user \"Copying timedout!\n\" }
   }
   expect eof { send_user \"Copied all files!\n\" }
"  

echo "Copying vpn client config and restart rosepc2 vpn service" | colorize BLUE

# Copy vpn client config and restart rosepc2 vpn service
expect -c "  
   exp_internal 0
   set timeout 4
   spawn ssh -t rose@$ROSEPC2_IP 
   expect {
      \"yes/no\" { send yes\n; exp_continue }
      \"password:\" { send $SCP_PASSWORD\n }
   }
   expect -re \".*\$\"

   send \"sudo rm -rf ${OPENVPN}/*.conf ${OPENVPN}/.vpn*\n\"
   expect {
      \"rose:\" { send $SCP_PASSWORD\n; exp_continue }
   }
   expect -re \".*\$\"
   sleep 1

   send \"sudo cp -rf ${ROSEPC2_KEYS} ${REMOTECLIENT_DIR}\n\"
   expect {
      \"rose:\" { send $SCP_PASSWORD\n; exp_continue }
   } 
   expect -re \".*\$\"
   sleep 1

    send \"vpn ${ROBOT_NAME}\n\"
   expect {
      \"rose:\" { send $SCP_PASSWORD\n; exp_continue }
   }
   expect -re \".*\$\"
   sleep 1

   send \"sudo /etc/init.d/openvpn restart \n\"
   expect -re \".*\$\"
   send \"sudo ufw allow 22 && sudo ufw allow from $(gethostip -d rosepc1) && sudo ufw allow from $(gethostip -d rosepc2)\n\"
   sleep 1
   expect -re \".*\$\"
   expect eof 
   exit
"
echo " "


echo "Restarting VPN server" | colorize BLUE

/etc/init.d/openvpn restart
sleep 1

echo "Opening ports" | colorize BLUE
ufw allow 22 && ufw allow from $(gethostip -d rosepc1) && ufw allow from $(gethostip -d rosepc2)

echo "Waiting 6s for VPN to start on both pc's..." | colorize BLUE
sleep 6
ping -c 1 -i 1 rosepc2

if [ $? != 0 ]; then
    echo "No VPN connection yet." | colorize YELLOW
    echo "Waiting 10s for VPN to start on both pc's..." | colorize BLUE
    sleep 10
fi

echo "Testing VPN..." | colorize BLUE
ping -c 3 -i 1 rosepc2 

if [ $? != 0 ]; then
    echo "No succes :(" | colorize RED
    exit 1
else
    echo "Succes, we can ping! :)" | colorize GREEN
    sleep 1

    sudo -u $USER $SSH_RSA_SCRIPT rosepc1 rose rose rosepc2 rose rose
    sudo -u $USER $SSH_RSA_SCRIPT rosepc2 rose rose rosepc1 rose rose

    echo " "
    echo "Finished setting up VPN on rosepc1 and rosepc2." | colorize GREEN
    echo "Have fun!" | colorize GREEN
    echo " "
fi

# Add shutdown etc to sudo users list for rose (for these commands to sudo password is asked)
${ROSE_TOOLS/scripts}/setup_rose_commands
