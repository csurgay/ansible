#!/bin/bash

log() {
        if [ $? -eq 0 ]
        then
                printf "\n##########################################\n"
                printf "Success: $1"
                printf "\n##########################################\n"
                printf "\n"
        else
                printf "\n##########################################\n"
                printf "ERROR: $1"
                printf "\n##########################################\n"
                printf "\n"
                exit 1
        fi
}

log "Setting up aliases for console access for hosts"

shopt -s expand_aliases
alias c0="sudo podman exec -it -u devops -w /home/devops/ansible/lessons ansible bash"
alias c1="sudo podman exec -it -u devops -w /home/devops host1 bash"
alias c2="sudo podman exec -it -u devops -w /home/devops host2 bash"
alias c3="sudo podman exec -it -u devops -w /home/devops host3 bash"

log "Usage script starting..."

sudo ./ansible_node/run_containers.sh

log "Containers are running"

cd ansible_node/setup_ssh
sudo ./setup_devops.sh

log "Control Node is set up"

