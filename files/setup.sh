#!/bin/bash
# Make sure you have the hosts set as your ansible inventory?
# /etc/ansible/hosts

# ----------------------------------------------
ANSIBLE_USER="artefactual"
ANSIBLE_KEY="$HOME/.ssh/id_rsa"
ANSIBLE_SUDO="artefactual.sudo"
ANSIBLE_SUDO_ETC="/etc/sudoers.d/$ANSIBLE_USER"

DOMAIN="example.com"
ATOM_EDIT_HOST="atom-edit.$DOMAIN"
ATOM_RO_HOST="atom-ro.$DOMAIN"
# ----------------------------------------------


function pause
{
    read -p 'press return...'
}


# Fetch the role from upstream:
if [ ! -d "roles" ]; then
    ansible-galaxy install -f -p roles -r requirements.yml
    pause
fi


if [ ! -s "$ANSIBLE_SUDO_ETC" ]; then
    echo "Allowing '$ANSIBLE_USER' to sudo without password..."
    sudo cp -av $ANSIBLE_SUDO $ANSIBLE_SUDO_ETC
    pause
fi


# Create SSH key for ansible access later:
if [ ! -s $ANSIBLE_KEY ]; then
    echo "exists"
    ssh-keygen -t rsa -f $ANSIBLE_KEY
    eval $(ssh-agent)   # From: https://www.cyberciti.biz/faq/how-to-use-ssh-agent-for-authentication-on-linux-unix/
    ssh-add $ANSIBLE_KEY
    pause
fi

# TODO: Create user automatically.
adduser $ANSIBLE_USER
ssh-copy-id $ANSIBLE_USER@$ATOM_EDIT_HOST
ssh-copy-id $ANSIBLE_USER@$ATOM_RO_HOST

