#!/bin/bash
ansible-playbook 01-setup.yml

echo "Vault password is: secret"

ansible-playbook --vault-id=@prompt 02-create.yml

ansible-playbook 03-copysshid.yml
