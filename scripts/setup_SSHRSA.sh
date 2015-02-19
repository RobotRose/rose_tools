#!/bin/bash  

# Setup the vars in robot_file.sh by sourcing the symlinked file in /usr/bin.
# This file is installed by running the first_install.sh script
source robot_file.sh

PC1=$1
PC1_USER=$2
PC1_PASS=$3
PC2=$4
PC2_USER=$5
PC2_PASS=$6

ping -c 1 -i 1 $PC1 2>&1 1> /dev/null
if [ $? != 0 ] || [ "$PC1_USER" == "" ] || [ "$PC1_PASS" == "" ]; then
    echo "First argument must be an reachable ip address or hostname." | colorize RED
    echo "Second argument must be the username of ${PC1}."  | colorize RED
    echo "Third argument must be the pass of ${PC1_USER} @ ${PC1}."  | colorize RED
    exit 1
else
    echo "First pc is: $PC1" | colorize GREEN
fi

ping -c 1 -i 1 $PC2 2>&1 1> /dev/null
if [ $? != 0 ] || [ "$PC2_USER" == "" ] || [ "$PC2_PASS" == "" ]; then
    echo "Fourth argument must be an reachable ip address or hostname." | colorize RED
    echo "Fifth argument must be the username of ${PC2}." | colorize RED
    echo "Sixed argument must be the password of ${PC2_USER} @ ${PC2}."  | colorize RED
    exit 1
else
    echo "Second pc is: $PC2" | colorize GREEN
fi


if [ -f ~/.ssh/*.pub ]; then
  echo "Not generating, we already have a public key." | colorize GREEN
else
# if [ "${NOGENERATE}" != "NO_GENERATE" ]; then

  echo -e "\nGenerating and pushing ssh rsa keys as user ${USER}..." | colorize GREEN

  PCNAME=$(uname -n)
  # sed -i'.bak' '/$PCNAME/d' ~/.ssh/authorized_keys && \
  echo -e "\nGenerating SSH key @ ${PC1}..." | colorize BLUE
  expect -c "
    set timeout 6
    spawn sudo -u $USER ssh -t $PC1_USER@$PC1 \" \ sed -i'.bak' '/$PCNAME/d' ~/.ssh/authorized_keys ; \
                                                ${ROSE_TOOLS}/scripts/setup_generate_SSHRSA\"
    expect {
    	\"yes/no\" { send yes\n; exp_continue }
    	\"password:\" { send $PC1_PASS\n }
    }
    expect eof
  "
fi

echo -e "\nPushing SSH key ${PC1} -> ${PC2}..." | colorize BLUE
expect -c "
  set timeout 6
  spawn sudo -u $USER ssh -t $PC1_USER@$PC1 \"${ROSE_TOOLS}/scripts/setup_push_SSHRSA $PC2_USER $PC2_PASS $PC2\"
  expect \"\$\"
  expect {
  	\"yes/no\" { send yes\n; exp_continue }
  	\"password:\" { send $PC1_PASS\n }
  }
  sleep 1
  expect eof
"


echo -e "\nSetting ssh-agent socket @${PC1}..." | colorize BLUE
expect -c "
  set timeout 6
  spawn sudo -u $USER ssh -t $PC1_USER@$PC1 \"source ${ROSE_TOOLS}/scripts/ssh-find-agent.bash set_ssh_agent_socket\"
  expect {
  	\"yes/no\" { send yes\n; exp_continue }
  	\"password:\" { send $PC1_PASS\n }
  	\"closed.\" { exit }
  }
  expect eof
"

echo -e "\n\nDone setting up ssh rsa key from ${PC1} -> ${PC2}." | colorize GREEN

exit 0
