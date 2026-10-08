# Section 5. Configuration

### In this section the following subjects will be covered:

1. Ansible Configuration (`ansible.cfg`)
1. Location of `ansible.cfg`
1. Ansible Log
1. Exercise: The `ansible-config` tool

---
### Ansible Configuration (`ansible.cfg`)

A typical ansible configuration file:

```ini
[defaults]
remote_user = devops
inventory = ./host_inventory
ask_pass = false
log_path = ./ansible.log
callback_result_format = yaml
interpreter_python = /usr/bin/python3

[privilege_escalation]
become = true
become_user = root
become_ask_pass = false
become_method = sudo
```

This is the `ansible.cfg` used in (almost) every lesson directory of this course.

Directives in the configuration file above

|Directive|Semantics|
|---------|---------|
| inventory | Path to the inventory file |
| remote_user | user to log in to the managed hosts, default is current user |
| ask_pass | Asking for SSH password, false for public key authentication |
| become | `true`/`false`: use privilege escalation (e.g. sudo) on the managed host |
| become_method | sudo is the default, su also can be used |
| become_user | Switch to this user on the managed host, default is root |
| become_ask_pass | Asking for sudo password (one for all hosts); `false` with passwordless sudo |
| log_path | Ansible will append all output to this file |
| callback_result_format | `yaml` or `json` (default) format of task results in the output |
| interpreter_python|Specifying exact location of python version suppresses warning in logs |

---
### Location of `ansible.cfg`

`ansible.cfg` can be placed in several possible locations, listed in ascending precedence.

```
/etc/ansible/ansible.cfg
~/.ansible.cfg
./ansible.cfg
export ANSIBLE_CONFIG=/home/devops/ansible/labenv/ansible.cfg
```

The environment variable has the highest precedence over all the others, and only **one** file is used
(settings are not merged). In this course every lesson directory has its own `./ansible.cfg`, so always run
Ansible from inside the lesson directory. Check which file is in effect with `ansible --version` (`config file =`).

> [!NOTE]
> For security reasons Ansible ignores `./ansible.cfg` in a world-writable directory.
> `stdout_callback = yaml`, found in many older examples, is deprecated; use `callback_result_format = yaml`.

---
### Ansible Log

Ansible prints verbose output to the terminal screen, but that is hard to follow and search for.

Good practice is to specify the `log_path=./ansible.log` in the configuration so that all output is appended into a file that can later be studied, searched for, etc.

---
### Exercise: The `ansible-config` tool

* locate and study `/etc/ansible/ansible.cfg`
* try `ansible-config list`
* try `ansible-config list | grep -i inventory`
* try `ansible-config dump`
* try `ansible-config dump | grep -i inventory`
* try `ansible-config view`
* try `ansible-config validate`
* try `ansible-config init > /tmp/ansible.cfg`




