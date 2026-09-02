#!/bin/bash

log() {
	if [ $? -eq 0 ]
	then
		printf "\n##################################################\n"
		printf "Success: $1"
		printf "\n##################################################\n"
		printf "\n"
	else
		printf "\n##################################################\n"
		printf "ERROR: $1"
		printf "\n##################################################\n"
		printf "\n"
		exit 1
	fi
}

log  "Setup user_ansible script started..."

podman exec -it ansible bash -c "useradd devops"
for i in {1..3}; do podman exec -it host$i bash -c "useradd devops"; done

log "User devops added to all containers"

podman exec -it ansible bash -c "echo 'devops:devops' | chpasswd"
for i in {1..3}; do podman exec -it host$i bash -c "echo 'devops:devops' | chpasswd"; done

log "Password for users set up"

podman exec -it -w /home/devops ansible bash -c "echo 'devops ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/devops"
for i in {1..3}; do podman exec -it -w /home/devops host$i bash -c "echo 'devops ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/devops"; done

log "NOPASSWD sudo for devops granted"

podman exec -u devops ansible bash -c 'ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -P ""'

log "Ssh key for devops in Control Node created"

podman exec -u devops ansible bash -c 'printf "devops" > /home/devops/pass'
podman exec -u devops ansible sshpass -f /home/devops/pass ssh-copy-id localhost
for i in {1..3}; do podman exec -u devops ansible sshpass -f /home/devops/pass ssh-copy-id host$i; done

log "SSH key is copied into Control Node and Managed Host containers"

podman exec -w /home/devops ansible rm -rvf ansible-training
podman exec -u devops -w /home/devops ansible git clone https://github.com/csurgay/ansible-training.git

log "Ansible Training Lab git repo cloned into Control Node"

podman cp ansible.cfg ansible:/home/devops/ansible-training/labenv/

log "Ansible config is saved in Controlnode container"

podman cp host_inventory ansible:/home/devops/ansible-training/labenv/

log "Ansible Inventory is saved in Controlnode container"

podman exec -u devops -w /home/devops/ansible-training/labenv ansible ansible all -m ping

log "Ansible accessing Managedhosts is tested OK"

log "Entring Control Node for lessons"

podman exec -it -u devops -w /home/devops/ansible-training/lessons ansible /bin/bash

