# Section 18: Tags

#### In this section the following subjects will be covered:

1. Understanding Ansible Tags
1. Adding Tags to Tasks, Plays and Roles
1. Listing Tags
1. Selecting and skipping Tags
1. The special Tags `always` and `never`
1. Tags and Facts
1. Tags with imports and includes
1. Best Practice

All examples are runnable in this directory (`ansible.cfg` and `host_inventory` included).

---
## Understanding Ansible Tags

Ansible tags let you run only selected parts of a Playbook. You add tags to Tasks, Blocks, Plays or Roles, and
with `ansible-playbook --tags` only the tasks with those tags run; with `--skip-tags` everything **except** them runs.

This is useful when you don't want to run the entire Playbook but only certain parts: e.g. only deploy a new config
file without reinstalling packages, or debug a single step.

Tags and conditions are different things: tags are selected from the **command line** by the person running the
Playbook, `when:` conditions are evaluated by Ansible from **variables and facts**. A selected task still checks
its `when:` condition.

---
## Adding Tags to Tasks

#### tags.yml
```yaml
---
- name: Webserver setup with tags
  hosts: myhosts
  become: true
  gather_facts: false

  tasks:

    - name: Install nginx
      ansible.builtin.dnf:
        name: nginx
        state: present
      tags: [install, webserver]

    - name: Install tools
      ansible.builtin.dnf:
        name: [tree, vim]
        state: present
      tags: [install, tools]

    - name: Configure index.html
      ansible.builtin.copy:
        content: "Tagged hello from {{ inventory_hostname }}\n"
        dest: /usr/share/nginx/html/index.html
        mode: '0644'
      tags: [configure, webserver]

    - name: Start nginx
      ansible.builtin.service:
        name: nginx
        state: started
        enabled: true
      tags: [start, webserver]

    - name: Always print where we are
      ansible.builtin.debug:
        msg: "Working on {{ inventory_hostname }}"
      tags: always

    - name: Clean up /tmp/backup (only when explicitly requested)
      ansible.builtin.file:
        path: /tmp/backup
        state: absent
      tags: [never, cleanup]
```

A tag on a Play, a Block or a Role (`roles: - role: tomcat_app, tags: tomcat`) is inherited by all of its tasks.

---
## Listing Tags

```bash
ansible-playbook tags.yml --list-tags
```

```
playbook: tags.yml

  play #1 (myhosts): Webserver setup with tags	TAGS: []
      TASK TAGS: [always, cleanup, configure, install, never, start, tools, webserver]
```

`--list-tasks` shows which tasks **would** run with a given selection, without running anything:

```bash
ansible-playbook tags.yml --tags webserver --list-tasks
```

---
## Selecting and skipping Tags

```bash
ansible-playbook tags.yml --tags install          # Install nginx, Install tools (+ the always task)
ansible-playbook tags.yml --tags webserver        # Install nginx, Configure, Start nginx (+ the always task)
ansible-playbook tags.yml --skip-tags configure   # everything except Configure index.html (and the never task)
```

> [!IMPORTANT]
> A list of tags means **any** of them (union, OR), not all of them:
> `--tags install,webserver` runs Install nginx, Install tools, Configure index.html **and** Start nginx (plus the `always` task) —
> every task that has `install` **or** `webserver`. There is no "AND" of tags on the command line.
> Check with `--list-tasks` before running.

`--tags` and `--skip-tags` can be combined: `--tags webserver --skip-tags start`.

---
## The special Tags `always` and `never`

- `always`: the task runs whatever `--tags` are given (it is skipped only with `--skip-tags always`).
  Use it for checks, setup, fact gathering.
- `never`: the task does **not** run by default, only when one of its **other** tags is requested explicitly
  (or with `--tags never`). Use it for dangerous or rarely needed tasks: cleanup, reset, debug output.

```bash
ansible-playbook tags.yml                    # "Clean up" does not run
ansible-playbook tags.yml --tags cleanup     # only "Always print..." and "Clean up" run
```

---
## Tags and Facts

If a Play has `gather_facts: false` and gathers facts with an explicit `setup` task, that task must be tagged
`always`, otherwise `--tags install_apache` would skip it and the `when:` conditions would fail on undefined facts.
(Automatic fact gathering at the start of a Play is always done, whatever tags are selected.)

#### tags_facts.yml
```yaml
---
- name: Facts and tags
  hosts: myhosts
  become: true
  gather_facts: false

  tasks:

    - name: Gather facts, whatever tags are selected
      ansible.builtin.setup:
      tags: always

    - name: Install httpd on the Red Hat family
      ansible.builtin.dnf:
        name: httpd
        state: present
      when: ansible_facts['os_family'] == "RedHat"
      tags: install_apache

    - name: Install apache2 on Debian/Ubuntu
      ansible.builtin.apt:
        name: apache2
        state: present
      when: ansible_facts['os_family'] == "Debian"
      tags: install_apache
```

```bash
ansible-playbook tags_facts.yml --tags install_apache
```

Try removing `tags: always` from the `setup` task and run the same command again.

---
## Tags with imports and includes

- `import_tasks` / `import_role` (static): tags on the import are inherited by **every** imported task.
- `include_tasks` / `include_role` (dynamic): a tag on the include only selects the include itself; to tag the
  tasks inside, use `apply:`

```yaml
- name: Import tasks, all of them get the tag "web"
  ansible.builtin.import_tasks: web.yml
  tags: web

- name: Include tasks, the included tasks get the tag "db" too
  ansible.builtin.include_tasks:
    file: db.yml
    apply:
      tags: db
  tags: db
```

---
## Best Practice

| Guideline | Good | Bad |
|-----------|------|-----|
| Descriptive names, consistent conventions | `install`, `configure`, `webserver` | `task1`, `stuff` |
| Few tags per task (2–3): one for the *phase*, one for the *component* | `[configure, webserver]` | `[web, websrv, webserver, www]` |
| Tag only tasks that make sense to run alone | config deployment, restart | a task that needs facts of a skipped task |
| Check the selection before running | `--tags x --list-tasks` | running `--tags` blind in production |
| Don't use tags to choose environments | `--limit production`, group_vars | `skip_in_production` tags |
| Keep `never` for explicit, dangerous actions | `[never, reset_db]` | hiding unfinished tasks |

Tags are not a replacement for variables and inventory groups: which **hosts** a Play touches is decided by the
inventory and `--limit`, what they should look like by variables; tags only select **which steps** run now.
