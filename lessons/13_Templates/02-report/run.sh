ansible-playbook report.yml
ansible host1 -m command -a "cat /tmp/report.txt"

ansible-playbook report_template.yml
ansible host1 -m command -a "cat /tmp/report.txt"
