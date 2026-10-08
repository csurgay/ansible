#!/bin/bash
# Acceptance test: prints the greeting from nginx.conf.j2 once the site works
ssh host1 curl -s localhost
echo
