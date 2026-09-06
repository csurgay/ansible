# Section 6. Playbooks

### In this section the following subjects will be covered:

1. Playbooks Introduction
1. YAML format
1. Configuration for Playbooks
1. Inventory for Playbooks
1. Sample Playbook
1. Running Playbook

---
### Playbooks Introduction

We learnt that the Ansible ad-hoc commands is a powerful tool to manipulate all kinds of states in managed hosts. But of course they can only carry out single tasks at a time. The real power of Ansible though is that complex tasks can be carried out by Playbooks. **Playbooks** can be seen as a collection of ad-hoc Ansible commands in an organized, documented, reusable manner to manipulate states of managed host. And of course Playbooks have a whole lot of other constructs and benefits to be discussed later.

Playbooks consist of muntiple **Plays**, each for a complex operation in itself, and Plays consist of **Tasks**. Tasks are the building blocks of complex operations, much like the ad-hoc commands we have seen so far.

Playbooks are written in **yaml** format, so let's go through it's basics firts.

---
### YAML format

YAML is much like JSON in terms of 

* key-value pairs
* lists
* dictionaries
* complex (or nested) objects
* comments

the main difference being the rigorous use of intendation (like in Python).

| Construct | JSON | YAML (__ is space intendation) |
| --------- | ---- | ---- |
| key-value pair | "key": value | key: value |
| list | ["a",1,"b"] | - "a"<br> - 1<br> - "b" |
| dict | tags:{"A": 1, "B": 2, "C": 3} | tags:<br>__A: 1<br>__B: 2<br>__C: 3 |
| nesting<br>(complex objects) | { "A": { "L": [ V1, V2 ], "K": 3 } } | A: <br> __"L": <br> __ __- V1 <br> __ __- V2 <br> __"K": 3 |
| comment | // comment | # comment |
| multiline strings | N/A | \| <br> multi <br> line <br> string |

There is also a multiline string option in YAML which comes handy when including scripts in other languages or SQL queries.

A copmplete Playbook looks like the one below. `---` is the start of the Playbook: a list of Plays. Each Play starts with a dash `-` symbol to indicate list element (see table above). Similarly `tasks:` of a Play is list of Tasks, so each Task starts with the dash `-` symbol.

---
### Configuration for Playbooks

`ansible.cfg` is the configuration for running Playbooks the same way as for ad-hoc commands.

#### ansible.cfg

A minimal config file for a simple playbook could be:

```yaml
[defaults]
interpreter_python=/usr/bin/python3
result_format=yaml
```

---
### Inventory for Playbooks

Inventory lists all hosts that Plays in a Playbook will potentially manage.

The same rules and locations apply for Playbooks Inventory than for ad-hoc commands Inventory.

#### myinventory.ini

A minimal inventory for this simple playbook could be:

```yaml
[ansible_controlnode]
localhost

[webservers]
host1
host2
```

---
### Sample Playbook

The sample Playbook below installs and starts an nginx service and tests it from the Control Node. Control Node is referred to as `localhost` because that is where the Playbook is run by Ansible.

You can use blank lines and comments anywhere to increase readability. Intendation however are handled rigorously: children have to be indented more than parents and siblings have to be intended exactly the same (much like in Python).

The Playbook below is saved e.g. in the file `sample_playbook.yml`. 

```
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
        state: latest

    - name: 2nd Task. Start nginx
      ansible.builtin.systemd:
        name: nginx
        state: started
        enabled: true

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
    - ansible.builtin.debug:
        var: result_curl
```

---
### Running a Playbook

Playbooks are run then with the command:
```bash
ansible-playbook -i ./myinventrory.ini sample_playbook.yml
```

Verbosity of output can be increased using the usual `-v`, `-vv`, `-vvv`, `-vvvv` options.

If you just want to check the syntax of your Playbook, use the `--syntax-check` option:  
`ansible-playbook -i ./myinventory.ini --syntax-check sample_playbook.yml`

If you just want Ansible to check what would be changed on Managed Hosts:  
`ansible-playbook -i ./myinventory.ini --check sample_playbook.yml`











