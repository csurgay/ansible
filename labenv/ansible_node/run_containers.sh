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

log "Run sctipt starting..."

podman rm -fa

log "All containers removed"

podman network list | grep nw_ansible
if [ $? -gt 0 ]
then
        podman network create nw_ansible
fi

log "Podman network nw_ansible created"

podman run --restart always --name ansible --hostname ansible -d --privileged --cap-add=ALL --security-opt seccomp=unconfined -v /sys/fs/cgroup:/sys/fs/cgroup:ro --tmpfs /run --tmpfs /run/lock -p 2020:22 --network nw_ansible --mac-address 10:10:10:10:10:10 docker.io/csurgay/ansible_node

log "Control Node container (ansible) started"

for i in {1..3}; do podman run --restart always --name host$i --hostname host$i -d --privileged --cap-add=ALL --security-opt seccomp=unconfined -v /sys/fs/cgroup:/sys/fs/cgroup:ro --tmpfs /run --tmpfs /run/lock -p 202$i:22 -p 808$i:80 --network nw_ansible --mac-address 10:10:10:10:10:1$i docker.io/csurgay/ansible_node; done

log "Managed Host containers (hosts) started"

sleep 3

for i in {1..3}; do podman inspect host$i | grep -E "IPAddress|MacAddress"; done

log "Container IP addresses listed"

