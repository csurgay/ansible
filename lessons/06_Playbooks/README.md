# Section 6. Playbooks

### In this section the following subjects will be covered:

1. Playbooks Introduction
1. YAML format
1. Configuration for Playbooks
1. Inventory for Playbooks
1. Sample Playbook
1. Running Playbook
1. Exercises

---
### Playbooks Introduction

We learnt that Ansible ad-hoc commands are a powerful tool to manipulate all kinds of states in managed hosts. But of course they can only carry out a single task at a time. The real power of Ansible is that complex tasks can be carried out by Playbooks. **Playbooks** can be seen as a collection of ad-hoc Ansible commands in an organized, documented, reusable manner to manipulate states of managed hosts. And of course Playbooks have a whole lot of other constructs and benefits to be discussed later.

Playbooks consist of one or more **Plays**, each for a complex operation in itself, and Plays consist of **Tasks**. Tasks are the building blocks of complex operations, much like the ad-hoc commands we have seen so far.

Playbooks are written in **YAML** format, so let's go through its basics first.

---
### YAML format

YAML is much like JSON in terms of

* key-value pairs
* lists
* dictionaries
* complex (or nested) objects

the main difference being the rigorous use of indentation (like in Python). YAML also supports comments, JSON does not.

| Construct | JSON | YAML (`__` is a space of indentation) |
| --------- | ---- | ---- |
| key-value pair | `{"key": "value"}` | `key: value` |
| list | `["a", 1, "b"]` | `- a`<br>`- 1`<br>`- b` |
| dict | `{"tags": {"A": 1, "B": 2, "C": 3}}` | `tags:`<br>`__A: 1`<br>`__B: 2`<br>`__C: 3` |
| nesting<br>(complex objects) | `{"A": {"L": ["V1", "V2"], "K": 3}}` | `A:`<br>`__L:`<br>`____- V1`<br>`____- V2`<br>`__K: 3` |
| comment | N/A | `# comment` |
| multiline strings | `"multi\nline\nstring"` | `script: \|`<br>`__multi`<br>`__line`<br>`__string` |

The multiline string option (`|` keeps the line breaks) comes handy when including scripts in other languages or SQL queries.

A complete Playbook is shown in the [Sample Playbook](#sample-playbook) section below. `---` is the start of the YAML document, which is a list of Plays. Each Play starts with a dash `-` symbol to indicate a list element (see table above). Similarly `tasks:` of a Play is a list of Tasks, so each Task starts with the dash `-` symbol.

---
### Configuration for Playbooks

`ansible.cfg` is the configuration for running Playbooks the same way as for ad-hoc commands.

#### ansible.cfg

A minimal config file for a simple playbook could be:

```ini
[defaults]
interpreter_python = /usr/bin/python3
callback_result_format = yaml
```

---
### Inventory for Playbooks

Inventory lists all hosts that Plays in a Playbook will potentially manage.

The same rules and locations apply for the Playbook Inventory as for the ad-hoc command Inventory.

#### myinventory.ini

A minimal inventory for this simple playbook could be:

```ini
[controlnode]
localhost

[webservers]
host1
host2
```

---
### Sample Playbook

The sample Playbook below installs and starts an nginx service, opens the firewall and tests it from the Control Node. The Control Node is referred to as `localhost` because that is where the Playbook is run by Ansible.

You can use blank lines and comments anywhere to increase readability. Indentation however is handled rigorously: children have to be indented more than parents and siblings have to be indented exactly the same (much like in Python).

The Playbook below is saved in the file `sample_playbook/sample_playbook.yml`, see the [sample_playbook lesson](sample_playbook/README.md) for a detailed walkthrough.

```yaml
---
# Comment: Sample Playbook of two Plays

- name: 1st Play. Install and start nginx
  hosts: webservers
  become: true
  gather_facts: false

  tasks:
    - name: 1st Task. Install nginx
      ansible.builtin.package:
        name: nginx
        state: present

    - name: 2nd Task. Start nginx
      ansible.builtin.systemd:
        name: nginx
        state: started
        enabled: true

    - name: 3rd Task. index.html
      ansible.builtin.copy:
        content: "Hi from {{ inventory_hostname }}!\n"
        dest: /usr/share/nginx/html/index.html
        mode: '0644'

    - name: 4th Task. Open port 80
      ansible.posix.firewalld:
        service: http
        permanent: true
        immediate: true
        state: enabled

- name: 2nd Play. Check return code 200
  hosts: localhost
  become: false
  gather_facts: false

  tasks:
    - name: Test nginx status code
      ansible.builtin.uri:
        url: "http://{{ item }}:80"
      loop: "{{ groups['webservers'] }}"
      register: result_curl

    - name: Print results
      ansible.builtin.debug:
        var: result_curl
```

---
### Running a Playbook

Playbooks are run with the `ansible-playbook` command, from the directory of the Playbook:

```bash
cd sample_playbook
ansible-playbook -i ./myinventory.ini sample_playbook.yml
```

Verbosity of output can be increased using the usual `-v`, `-vv`, `-vvv`, `-vvvv` options.

To check the syntax of your Playbook without running it, use the `--syntax-check` option:
`ansible-playbook -i ./myinventory.ini --syntax-check sample_playbook.yml`

To dry run your Playbook (check what would be changed without changing anything) on Managed Hosts, use the `--check` option:
`ansible-playbook -i ./myinventory.ini --check sample_playbook.yml`

---
### Exercises

Work through the subdirectories in this order:

| Lesson | Topics |
|--------|--------|
| [sample_playbook](sample_playbook/README.md) | Anatomy of a Playbook, two Plays, `package`, `systemd`, `firewalld`, `uri`, `loop`, `register` |
| [00-command-shell](00-command-shell/README.md) | Your own project directory, `command` vs `shell`, `register` + `debug` |
| [01-haproxy](01-haproxy/README.md) | Install and configure a service from a config file: `dnf`, `file`, `copy`, `firewalld`, `systemd` |
| [02-raw](02-raw/README.md) | Running commands without Python with `raw`, `changed_when`, `check_mode` |

More complex, real-life playbooks (users, sshd, backups, time sync, troubleshooting...) follow in
[14_LinuxAdminLabs](../14_LinuxAdminLabs/README.md), once Variables, Vault, Control Flow and Templates are covered.
