# Command, Shell

### In this lesson the following subjects are covered

1. Set up your Ansible project directory
1. Prepare an `inventory` file
1. Prepare a simple `ansible.cfg` config file 
1. Smoke test Ansible can access your inventory hosts

---
## Set up your Ansible project directory
```bash
cd
mkdir playbook
cd playbook
```

---
## Prepare an inventory file
```bash
vim host_inventory
```
#### host_inventory
```yaml
[controlnode]
localhost

[myhosts]
host1
host2
host3
```

---
## Prepare a simple ansible.cfg config file
```bash
vim ansible.cfg
```
#### ansible.cfg
```yaml
[defaults]
interpreter_python=/usr/bin/python3
result_format=yaml
```

---
## Smoke test Ansible can access your target hosts
```bash
ansible all -m ping
```

---
## Write a simple Playbook

- Playbooks are yaml files, so they always start with `---`
- Good practice to start Playbooks with a descriptive yaml comment above the `---`
- Playbooks are a yaml list of Plays, so each Play start with `-` (yaml list item)
- Plays are a header followed by a tasklist
- Header is a yaml dictionary, so key-value pairs, colon appended to keys
- Always `name:` your Plays in the first key-value pair so that you can navigate you output and logs
- Other header keys are
  - `hosts:` for set of actual target hosts
  - `become:` for the privilege escalation on the Managed Hosts
  - `gather_facts:` to spend time on or omit the gathering of system facts from Managed Hosts
  - `tasks:` is the yaml list of modules of this Play to execute on the Managed Hosts

So far we have:

```yaml
# Descriptive comment of this Playbook
--- 
- name: Play description
  hosts: all
  become: true
  gather_facts: false
  tasks:
```

Under tasks you enlist all modules of this Play to be executed on the Managed Hosts.

In the Tasks section `tasks:` is the key, and its value is a yaml list of multiple Tasks.
Every one Task is a yaml list item that consitst a yaml dictionary with keys like

+ `name:` to have a description of the Task that can also be found in output and logs
+ a module name like `ansible.builtin.debug` where the value is a yaml dictionary of arguments for this module
+ `register:` to record the result of the Task into a new variable
+ `loop:` if you need to run the Task multiple times over the `item`s of a list
+ `when:` if you only want to run the Task on some conditions
+ `become:` if you need to cause or prevent privilege escalation only for this Task
+ `ignore_errors:` of you need to keep on executing the Play even if this Task fails on a Managed Host
+ `no_log`: if you don't want the result of this Task in your output or logs

In this lesson we have two modules to learn

+ ansible.builtin.command
+ ansible.builtin.debug

in two Tasks as follows:

```yaml
# Descriptive comment of this Playbook
--- 
- name: Play description
  hosts: all
  become: true
  gather_facts: false

  tasks:

    - name: Uptime
      ansible.builtin.command: uptime
      register: result_uptime

    - name: Print result
      ansible.builtin.debug:
        var: result_uptime.stdout_lines
```

---
### Shell module in Playbook

It the next Playbook we need the `ansible.builtin.shell` module because output redirection is not executed by `command`, it requires the bash shell parsing. Note that this Playbook has the same structure and will use the same inventory and config file because it is located in the same Ansible project directory.

```yaml
# Usage of shell module in bash parsing is required (e.g. pipes, redirections, etc.)
---
- name: Listing files
  hosts: all
  become: true
  gather_facts: false

  tasks:

    - name: Listing
      ansible.builtin.shell: "ls -la /etc/ssh/ > /tmp/sshdir.lst"
      register: result_listing

    - name: Print result
      ansible.builtin.debug:
        var: result_listing.stdout_lines
```
