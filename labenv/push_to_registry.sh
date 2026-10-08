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

log "Push script starting..."

podman login docker.io

podman push docker.io/csurgay/ansible_node

log "ansible_node image is pushed to public registry"

