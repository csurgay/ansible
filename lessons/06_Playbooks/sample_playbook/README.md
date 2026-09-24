# Sample Playbook

### In this lesson the following subjects are covered

1. Anatomy of a Playbook: Plays, Tasks and modules
1. Target different host groups from a custom inventory file
1. Install, start and expose a service with `package`, `systemd` and `firewalld`
1. Put two Plays in one Playbook
1. Test the webservers from the Control Node with `uri` and `loop`
1. Collect results across loop iterations with `register` and `set_fact`

---
## Anatomy of a Playbook

A Playbook is a YAML file holding a **list of Plays**. Each Play maps a group of hosts (`hosts:`) to an ordered list of **Tasks**, and each Task calls exactly one **module** with its parameters. The Play-level keywords set the context for every Task inside it:

- `name` — free text, printed in the output, so make it describe the intent
- `hosts` — which inventory group (or host) the Play runs against
- `become: true` — run the Tasks with root privileges (via `sudo`)
- `gather_facts: false` — skip the fact-gathering step, making the Play start faster when facts are not needed

Lines starting with `#` are comments, and the leading `---` marks the start of a YAML document.

---
## Target different host groups from a custom inventory file

This lesson ships its own inventory, `myinventory.ini`, with two groups: the Control Node itself and the two webservers.

#### myinventory.ini
```ini
[ansible_controlnode]
localhost

[webservers]
host1
host2
```

Since `ansible.cfg` here does not set an `inventory`, it has to be passed on the command line with `-i`. `result_format=yaml` makes registered results and `debug` output much easier to read than the default JSON.

#### ansible.cfg
```ini
[defaults]
interpreter_python=/usr/bin/python3
result_format=yaml
```

---
## Install, start and expose a service

The 1st Play runs on the `webservers` group and turns each host into a working nginx server in three Tasks:

- `ansible.builtin.package` — the distribution-agnostic package module (it picks `dnf`, `apt`, … on its own). `state: latest` installs nginx and also upgrades it if a newer version is available; `state: present` would only make sure it is installed.
- `ansible.builtin.systemd` — `state: started` starts the service if it is not running, and `enabled: true` makes it start on boot as well.
- `ansible.builtin.firewalld` — `service: http` with `state: enabled` opens port 80 in the firewall.

Each of these is **idempotent**: run the Playbook a second time and every Task reports `ok` instead of `changed`, because the desired state is already there.

---
## Put two Plays in one Playbook

A single Playbook can contain several Plays, each with its own `hosts`, `become` and `tasks`. They run top to bottom: the 2nd Play only starts once the 1st Play has finished on all hosts. This is how you mix "configure the servers" and "test them from somewhere else" in one run — here the 2nd Play runs on `localhost`, the Control Node, and needs no root privileges (`become: false`).

---
## Test the webservers from the Control Node

`ansible.builtin.uri` sends an HTTP request and, by default, **fails the Task unless the response status is 200** — so the Task itself acts as the test. `loop` repeats the Task once per item, and `groups['webservers']` is a magic variable holding the list of hosts in that inventory group, so each webserver gets requested in turn with `{{ item }}` substituted into the URL.

`register` saves the Task's result into a variable. With a `loop`, the registered variable holds one entry per iteration under `.results`.

#### sample_playbook.yml
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
        state: latest

    - name: 2nd Task. Start nginx
      ansible.builtin.systemd:
        name: nginx
        state: started
        enabled: true

    - name: 3rd Task. index.html
      ansible.builtin.shell:
         echo "Hi from {{ ansible_host }}!" > /usr/share/nginx/html/index.html

    - name: 4th Task. Open port 80
      ansible.builtin.firewalld:
        service: http
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
    - ansible.builtin.debug:
        var: result_curl
```

---
## Running the Playbook

```bash
ansible-playbook -i myinventory.ini sample_playbook.yml
```

Look at the `debug` output at the end: `result_curl.results` has one entry per webserver, each with `status: 200`, the `url` it called, and the `item` it was looping over. Run the Playbook a second time and notice that every Task in the 1st Play reports `ok`.

---
## Collect results across loop iterations

`check_content.yml` repeats only the test part, this time fetching the actual page content with `curl` through the `command` module. The `stdout` of each iteration is then collected into a single list:

- `vars: outstr_list: []` starts with an empty list
- `ansible.builtin.set_fact` loops over `result_curl.results` and appends each `item.stdout` to the list — `set_fact` creates or overwrites a variable at runtime, so the list grows by one element per iteration
- `no_log: true` keeps the (long) loop output from flooding the terminal
- the final `debug` prints only the clean list of page contents

A Task does not need a `name`, but unnamed Tasks show up in the output only by module name — compare them with the named ones.

#### check_content.yml
```yaml
- name: 2nd Play. Check return code 200
  hosts: localhost
  become: false
  gather_facts: false
  vars:
    outstr_list: []

  tasks:
    - name: Test nginx webserver return content
      ansible.builtin.command:
        cmd: curl -s http://{{ item }}:80
      loop: "{{ groups['webservers'] }}"
      register: result_curl
    - ansible.builtin.set_fact:
        outstr_list:  "{{ outstr_list + [item.stdout] }}"
      loop: "{{ result_curl.results }}"
      no_log: true
    - ansible.builtin.debug:
        var: outstr_list
```

---
## Running the Playbook

```bash
ansible-playbook -i myinventory.ini check_content.yml
```

The output is a list with one element per webserver: the HTML of the default nginx welcome page.

Tip: the same list can be built without the `set_fact` loop, with a Jinja2 filter chain:

```yaml
    - ansible.builtin.debug:
        msg: "{{ result_curl.results | map(attribute='stdout') | list }}"
```
