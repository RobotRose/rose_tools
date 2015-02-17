#!/bin/bash  

ssh-keygen -R rosepc1
ssh-keygen -R rosepc2
expect -c "  
    set timeout 4
    spawn bash
    expect -re ".*\$"
    send \"ssh -oHostKeyAlgorithms='ssh-rsa' rose@rosepc1 \r\"
    expect yes/no { send yes\r ; exp_continue }
    expect password: { send $SCP_PASSWORD\r}
    expect -re ".*\$"
    sleep 2
    exit 
"
expect -c "  
    set timeout 4
    spawn bash
    expect -re ".*\$"
    send \"ssh -oHostKeyAlgorithms='ssh-rsa' rose@rosepc2 \r\"
    expect yes/no { send yes\r ; exp_continue }
    expect password: { send $SCP_PASSWORD\r}
    expect -re ".*\$"
    sleep 2
    exit 
"
echo "SSH known hosts setup done."
