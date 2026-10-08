#!/bin/bash
# Usage: ./run.sh [httpd|nginx]
ansible-playbook -e webserver="${1:-nginx}" webserver.yml
