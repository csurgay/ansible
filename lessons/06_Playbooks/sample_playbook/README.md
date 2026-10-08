# Sample Playbook

### In this lesson the following subjects are covered

1. Anatomy of a Playbook: Plays, Tasks and modules
1. Target different host groups from a custom inventory file
1. Install, start and expose a service with `package`, `systemd`, `copy` and `firewalld`
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
[controlnode]
localhost

[webservers]
host1
host2
```

Since `ansible.cfg` here does not set an `inventory`, it has to be passed on the command line with `-i`. `callback_result_format = yaml` makes registered results and `debug` output much easier to read than the default JSON.

#### ansible.cfg
```ini
[defaults]
interpreter_python = /usr/bin/python3
callback_result_format = yaml
```

---
## Install, start and expose a service

The 1st Play runs on the `webservers` group and turns each host into a working nginx server in four Tasks:

- `ansible.builtin.package` — the distribution-agnostic package module (it picks `dnf`, `apt`, … on its own). `state: present` makes sure nginx is installed; `state: latest` would also upgrade it whenever a newer version appears, which makes runs less predictable.
- `ansible.builtin.systemd` — `state: started` starts the service if it is not running, and `enabled: true` makes it start on boot as well.
- `ansible.builtin.copy` with `content:` — writes a small `index.html`. `inventory_hostname` is a magic variable holding the name of the current host, so every server greets with its own name.
- `ansible.posix.firewalld` — `service: http` with `state: enabled` opens port 80 in the firewall; `permanent: true` keeps it after a reload, `immediate: true` applies it right away. Note the collection name: `firewalld` is not part of `ansible.builtin`.

Each of these is **idempotent**: run the Playbook a second time and every Task reports `ok` instead of `changed`, because the desired state is already there.

> [!TIP]
> Compare with `ansible.builtin.shell: echo "Hi" > /usr/share/nginx/html/index.html`: it would report `changed` on every run, because Ansible cannot know what an arbitrary shell command did. Prefer a real module whenever one exists.

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
## Running the Playbook

```bash
ansible-playbook -i myinventory.ini sample_playbook.yml
```

Look at the `debug` output at the end: `result_curl.results` has one entry per webserver, each with `status: 200`, the `url` it called, and the `item` it was looping over. Run the Playbook a second time and notice that every Task in the 1st Play reports `ok`.

**Try this:** run it once more with `--check --diff`, then change the greeting in Task 3 and run `--check --diff` again.

---
## Collect results across loop iterations

`check_content.yml` repeats only the test part, this time fetching the actual page content with `uri` and `return_content: true`. The `content` of each iteration is then collected into a single list:

- `vars: outstr_list: []` starts with an empty list
- `ansible.builtin.set_fact` loops over `result_curl.results` and appends each `item.content` to the list — `set_fact` creates or overwrites a variable at runtime, so the list grows by one element per iteration
- `no_log: true` keeps the (long) loop output from flooding the terminal
- the final `debug` prints only the clean list of page contents

A Task does not strictly need a `name`, but unnamed Tasks show up in the output only by module name — always name them.

#### check_content.yml
```yaml
---
- name: Check the content served by the webservers
  hosts: localhost
  become: false
  gather_facts: false
  vars:
    outstr_list: []

  tasks:
    - name: Test nginx webserver return content
      ansible.builtin.uri:
        url: "http://{{ item }}:80"
        return_content: true
      loop: "{{ groups['webservers'] }}"
      register: result_curl

    - name: Collect page contents into a list
      ansible.builtin.set_fact:
        outstr_list: "{{ outstr_list + [item.content] }}"
      loop: "{{ result_curl.results }}"
      no_log: true

    - name: Print the list
      ansible.builtin.debug:
        var: outstr_list
```

---
## Running the Playbook

```bash
ansible-playbook -i myinventory.ini check_content.yml
```

The output is a list with one element per webserver: the `Hi from host1!` / `Hi from host2!` pages written by `sample_playbook.yml`.

Tip: the same list can be built without the `set_fact` loop, with a Jinja2 filter chain:

```yaml
    - ansible.builtin.debug:
        msg: "{{ result_curl.results | map(attribute='content') | list }}"
```
