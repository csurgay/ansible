# Command, Shell

### In this lesson the following subjects are covered

1. Set up your Ansible project directory
1. Prepare an `inventory` file
1. Prepare a simple `ansible.cfg` config file 
1. Smoke test Ansible can access your inventory hosts
1. Write Playbooks with the `command`, `shell` and `debug` modules

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
```ini
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
```ini
[defaults]
inventory = ./host_inventory
remote_user = devops
interpreter_python = /usr/bin/python3
callback_result_format = yaml

[privilege_escalation]
become_method = sudo
become_ask_pass = false
```

`inventory =` makes `-i host_inventory` unnecessary. (The `ansible.cfg` shipped in this directory is the full
version used in most lessons, see [05_Configuration](../../05_Configuration/README.md).)

---
## Smoke test Ansible can access your target hosts
```bash
ansible all -m ping
```

---
## Write a simple Playbook

- Playbooks are yaml files, so they usually start with `---`
- Good practice to start Playbooks with a descriptive yaml comment
- Playbooks are a yaml list of Plays, so each Play starts with `-` (yaml list item)
- Plays are a header followed by a tasklist
- Header is a yaml dictionary, so key-value pairs, colon appended to keys
- Always `name:` your Plays in the first key-value pair so that you can navigate your output and logs
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
  become: false
  gather_facts: false
  tasks:
```

Under tasks you enlist all modules of this Play to be executed on the Managed Hosts.

In the Tasks section `tasks:` is the key, and its value is a yaml list of multiple Tasks.
Every Task is a yaml list item that consists of a yaml dictionary with keys like

+ `name:` to have a description of the Task that can also be found in output and logs
+ a module name like `ansible.builtin.debug` where the value is a yaml dictionary of arguments for this module
+ `register:` to record the result of the Task into a new variable
+ `loop:` if you need to run the Task multiple times over the `item`s of a list
+ `when:` if you only want to run the Task on some conditions
+ `become:` if you need to cause or prevent privilege escalation only for this Task
+ `ignore_errors:` if you need to keep on executing the Play even if this Task fails on a Managed Host
+ `no_log:` if you don't want the result of this Task in your output or logs

Most of these keywords come later in the course. In this lesson we have two modules to learn

+ ansible.builtin.command
+ ansible.builtin.debug

in two Tasks as follows:

#### command.yml
```yaml
# Usage of the command module: run a single command, no shell features
---
- name: Check uptime
  hosts: all
  become: false
  gather_facts: false

  tasks:

    - name: Uptime
      ansible.builtin.command: uptime
      register: result_uptime

    - name: Print result
      ansible.builtin.debug:
        var: result_uptime.stdout_lines
```

```bash
ansible-playbook command.yml
```

---
### Shell module in Playbook

In the next Playbook we need the `ansible.builtin.shell` module, because pipes (`|`) and output redirection (`>`) are not executed by `command`: they require the bash shell parsing. Note that this Playbook has the same structure and uses the same inventory and config file because it is located in the same Ansible project directory.

#### shell.yml
```yaml
# Usage of the shell module: bash parsing is required (e.g. pipes, redirections, etc.)
---
- name: Listing files
  hosts: all
  become: true
  gather_facts: false

  tasks:

    - name: List the SSH host keys (pipe needs the shell)
      ansible.builtin.shell: "ls -la /etc/ssh/ | grep ssh_host"
      register: result_listing

    - name: Print result
      ansible.builtin.debug:
        var: result_listing.stdout_lines

    - name: Save the listing into a file (redirection needs the shell)
      ansible.builtin.shell: "ls -la /etc/ssh/ > /tmp/sshdir.lst"

    - name: Read the file back
      ansible.builtin.command: cat /tmp/sshdir.lst
      register: result_file

    - name: Print file content
      ansible.builtin.debug:
        var: result_file.stdout_lines
```

```bash
ansible-playbook shell.yml
```

**Try this:** change the first task to `ansible.builtin.command` and run it again. What happens to the `|`?
