#!/bin/bash  

SSH_RSA_SCRIPT="$ROSE_TOOLS/scripts/setup_SSHRSA.sh"
VPN_CONFIGS_DIR="/etc/openvpn"
SET_VPN_NAME=$1
selectednr=-1

if [ "$SET_VPN_NAME" == "" ]; then
  


    # Check if we are sudo user
    if [ "$(id -u)" != "0" ]; then
        echo -e "Sorry, you are not root, run with sudo." | colorize RED
        exit 1
    fi

    # Check if dialog is installed
    dialog 2>&1 1> /dev/null

    if [ $? == 127 ]; then
        echo "Installing dialog." | colorize BLUE
        apt-get install -y --force-yes dialog 
    fi

    nr="$(ls -a ${VPN_CONFIGS_DIR}/ | grep -c .vpn_client_)"
    if [ "$nr" == "0" ]; then
        echo "No VPN configurations found, run the transfer_vpn_config script to transfer vpn configs." | colorize RED
        exit 1
    fi

    i="0"
    options=""
    while [ $i -lt $nr ]
    do
      new="$[$i+1] $(ls -a ${VPN_CONFIGS_DIR}/ | grep .vpn_client_ | sed -n $[$i+1]p) "
      echo "New option: $new"
      options="${options}${new}"
      i=$[$i+1]
    done
    options2=($options)

    dialog --title "Select VPN configuration" \
        --backtitle "Select VPN configuration" \
        --clear \
        --menu "Select VPN configuration" 40 80 22 ${options2[@]} 2>/tmp/vpn_dialog.ans

    result=$(cat /tmp/vpn_dialog.ans)
    if [ "$result" == "" ]; then
        echo "Canceled." | colorize BLUE
        exit 1
    fi
    selectednr=$result
else

    nr="$(ls -a /etc/openvpn/ | grep -c .vpn_client_${SET_VPN_NAME})"
    if [ "$nr" == "0" ]; then
        echo "Invalid vpn config name provided: ${SET_VPN_NAME}."
        exit 1
    fi

    selectednr="$(ls -a /etc/openvpn/ | grep .vpn_client_ | grep -n ${SET_VPN_NAME} | cut -f1 -d:)"
    echo "Auto setting VPN ${SET_VPN_NAME}, number ${selectednr}." | colorize BLUE

fi

selected="$(ls -a ${VPN_CONFIGS_DIR}/ | grep .vpn_client_ | sed -n ${selectednr}p)"

echo "Selected VPN configuration ${selected}." | colorize BLUE

echo "Checking for old VPN configurations." | colorize BLUE
remove=$(find /etc/openvpn -type l)
if [ "$remove" != "" ]; then
    echo "Removing old VPN configurations." | colorize BLUE
    find /etc/openvpn -type l | xargs rm
    if [ $? != 0 ]; then
        echo "Error: Could not remove old VPN configurations." | colorize RED
        exit 1
    fi
else
    echo "No old configurations found."
fi

echo "Creating new symlink to selected VPN configuration." | colorize BLUE
ln -f -s ${VPN_CONFIGS_DIR}/${selected}/*.conf /etc/openvpn/

if [ $? != 0 ]; then
    echo "Error creating symlink for VPN configuration $selected." | colorize RED
    exit 1
fi

echo "Restarting openvpn service." | colorize BLUE
service openvpn restart

echo -en "Waiting for connection to setup password-less connection (max 10s), ctrl+C to skip" | colorize BLUE

i="0"
CONNECTED="FALSE"
while [ $i -lt 10 ] 
do
    trap break SIGINT SIGTERM SIGTSTP
    echo -en "." | colorize YELLOW
    ping -c 1 -i 1 -w 1 rosepc1 2>&1 1> /dev/null
    PC1=$?
    ping -c 1 -i 1 -w 1 rosepc2 2>&1 1> /dev/null
    PC2=$?
    if [ $PC1 == 0 ]; then
    	echo -en "\nSuccesfull connection to rosepc1, now testing rosepc2...\n" | colorize GREEN
        if [ $PC2 == 0 ]; then
            CONNECTED="TRUE"
            echo -en "\nSucces, we are connected to ${selected}.\n" | colorize GREEN
            break
        fi
    fi
    i=$[$i+1]
done

# untrap
trap - SIGINT SIGTERM SIGTSTP

if [ "$CONNECTED" == "TRUE" ]; then
    echo "Setting up known_hosts file." | colorize BLUE
    $ROSE_TOOLS/scripts/setup_known_hosts.sh rosepc1 > /dev/null 2>&1 
    $ROSE_TOOLS/scripts/setup_known_hosts.sh rosepc2 > /dev/null 2>&1

    MYIP=$(ifconfig | grep "inet addr:10.8.0." | grep -oP 'inet addr:\K([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})')

    read -s -p "Please enter password for user ${SUDO_USER}: " PASS
    stty sane
    echo -en "\nSetting up password-less connection, this can take a second, or five...\n" | colorize BLUE
    sudo -u ${SUDO_USER} $SSH_RSA_SCRIPT rosepc1 rose rose ${MYIP} ${SUDO_USER} ${PASS} > /dev/null 2>&1
    sudo -u ${SUDO_USER} $SSH_RSA_SCRIPT rosepc2 rose rose ${MYIP} ${SUDO_USER} ${PASS} > /dev/null 2>&1
    
    sudo -u ${SUDO_USER} $SSH_RSA_SCRIPT ${MYIP} ${SUDO_USER} ${PASS} rosepc1 rose rose  > /dev/null 2>&1
    sudo -u ${SUDO_USER} $SSH_RSA_SCRIPT ${MYIP} ${SUDO_USER} ${PASS} rosepc2 rose rose  > /dev/null 2>&1
else
    echo -en "\nNot connected, skipping configuring known_hosts and RSA keys.\n" | colorize YELLOW
fi

echo -en "\nDone.\n" | colorize GREEN

exit 0
