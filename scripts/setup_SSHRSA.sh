#!/bin/bash  

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

echo "ROSE_TOOLS = $ROSE_TOOLS"
sleep 5

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
    spawn rsync -Ive ssh ${ROSE_TOOLS}/scripts/setup_generate_SSHRSA $PC1_USER@$PC1:~/gen_SSHRSA
    expect {
      \"yes/no\" { send yes\n; exp_continue }
      \"password:\" { send $PC1_PASS\n }
    }
    expect \"\$\"

    spawn sudo -u $USER ssh -t $PC1_USER@$PC1 \" \ sed -i'.bak' '/$PCNAME/d' ~/.ssh/authorized_keys ; ~/gen_SSHRSA; rm ~/gen_SSHRSA\"
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
  spawn rsync -Ive ssh ${ROSE_TOOLS}/scripts/setup_push_SSHRSA $PC1_USER@$PC1:~/push_SSHRSA
  expect {
    \"yes/no\" { send yes\n; exp_continue }
    \"password:\" { send $PC1_PASS\n }
  }
  expect \"\$\"

  spawn sudo -u $USER ssh -t $PC1_USER@$PC1 \"~/push_SSHRSA $PC2_USER $PC2_PASS $PC2; rm ~/push_SSHRSA \"
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
  spawn rsync -Ive ssh ${ROSE_TOOLS}/scripts/ssh-find-agent.bash $PC1_USER@$PC1:~/ssh-find-agent.bash
  expect {
    \"yes/no\" { send yes\n; exp_continue }
    \"password:\" { send $PC1_PASS\n }
  }
  expect \"\$\"

  spawn sudo -u $USER ssh -t $PC1_USER@$PC1 \"~/ssh-find-agent.bash set_ssh_agent_socket; rm ~/ssh-find-agent.bash\"
  expect {
  	\"yes/no\" { send yes\n; exp_continue }
  	\"password:\" { send $PC1_PASS\n }
  	\"closed.\" { exit }
  }
  expect eof
"

echo -e "\n\nDone setting up ssh rsa key from ${PC1} -> ${PC2}." | colorize GREEN

exit 0
