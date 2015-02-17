#!/bin/bash

HOSTNAME=$1
IP=$(gethostip -d ${HOSTNAME})

if [ "$HOSTNAME" == "" ]; then
    echo "First argument must specify the hostname."
    exit 1
fi

ssh-keygen -f "~/.ssh/known_hosts" -R ${HOSTNAME}

ssh-keygen -R ${HOSTNAME}
ssh-keygen -R ${IP}
ssh-keygen -R ${HOSTNAME},${IP}
ssh-keyscan -H ${HOSTNAME},${IP} >> ~/.ssh/known_hosts
ssh-keyscan -H ${IP} >> ~/.ssh/known_hosts
ssh-keyscan -H ${HOSTNAME} >> ~/.ssh/known_hosts

exit 0
