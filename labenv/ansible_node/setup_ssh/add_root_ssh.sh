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

log "Setup sctipt starting..."

podman exec -w=/root ansible rm -rvf ansible-training
podman exec -w=/root ansible git clone https://github.com/csurgay/ansible-training.git

log "Training lab is pulled from Git to Controlnode container"

podman cp ansible.cfg ansible:/root/ansible-training/labenv/

log "Ansible config is saved in Controlnode container"

podman cp host_inventory ansible:/root/ansible-training/labenv/

log "Ansible Inventory is saved in Controlnode container"

for i in {1..3}; do str="$(podman network inspect nw_ansible | grep -A5 host$i | grep ip | sed s/\ //g | sed s/.*:\"// | sed s'/\/.*//') host$i"; podman exec ansible bash -c "echo $str >> /etc/hosts"; done

log "Managed hosts IP addresses is saved in Controlnode container"

podman exec -u root ansible bash -c 'ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -P ""'

log "SSH key is generated for root in Controlnode container"

podman exec ansible bash -c 'printf "root" > /root/pass'

podman exec ansible sshpass -f /root/pass ssh-copy-id localhost
for i in {1..3}; do podman exec ansible sshpass -f /root/pass ssh-copy-id host$i; done

log "SSH key is copied into Managedhost containers"

podman exec -w /root/ansible-training/labenv ansible ansible myhosts -m ping

log "Ansible accessing Managedhosts is tested OK"

podman exec -it -w /root/ansible-training/lessons ansible bash

