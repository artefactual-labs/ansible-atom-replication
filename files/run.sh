#!/bin/bash

PLAYBOOK="mgt.replication-aph-role.yml"

echo ""
echo "Unlock SSH keys and add them to ssh-agent..."
echo ""
eval $(ssh-agent)
ssh-add


echo ""
echo "List and ping hosts for line-check..."
echo ""

ansible all --list-hosts
ansible all -m ping


echo ""
echo "Run the playbook..."
echo ""

ansible-playbook $PLAYBOOK -e atom_replication_ansible_remote_server=atom-edit-server -t install-replication

