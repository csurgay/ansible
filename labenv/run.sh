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

log "Usage script starting..."

sudo ./ansible_node/run_containers.sh

log "Containers are running"

cd ansible_node/setup_ssh
sudo ./setup_devops.sh

log "Control Node is set up"

