# Section 15. Roles

### In this section the following subjects will be covered:

1. Introduction to Roles
1. Roles Directory Structure
1. Roles Locations
1. Using Roles: play level, include, import
1. Exercises
1. Ansible Galaxy
1. Linux System Roles

---
## Introduction to Roles

Roles are shareable and reusable units of Ansible automation that follow a predefined directory structure
(tasks, vars, templates, handlers, tests, files, etc).

Roles can be called from your Playbooks, and can be given parameters specific to your application.

---
## Roles Directory Structure

```
roles/
    myrole1/              # this hierarchy represents a "role"
        tasks/            #
            main.yml      #  <-- tasks, can include other task files
        handlers/         #
            main.yml      #  <-- handlers file
        templates/        #  <-- files for the template module
            ntp.conf.j2   #  <------- templates end in .j2
        files/            #
            mytext.txt    #  <-- files to copy
            myscript.sh   #  <-- script files for use with the script module
        vars/             #
            main.yml      #  <-- variables for this role, high precedence
        defaults/         #
            main.yml      #  <-- default variables for this role, lowest precedence
        meta/             #
            main.yml      #  <-- role metadata and dependencies
```

Create the skeleton with:

```bash
ansible-galaxy role init myrole1
```

---
## Roles Locations

Roles can be placed in the `roles/` subdirectory next to the Playbook file, or at the `roles_path` config key
locations, with its default values:

- `~/.ansible/roles`
- `/usr/share/ansible/roles`
- `/etc/ansible/roles`

---
## Using Roles

### Play level Roles

Roles listed under `roles:` run before the `tasks:` of the Play. Below one role without and one with parameters.

```yaml
---
- name: Play level Roles
  hosts: all
  roles:
    - myrole1
    - role: myrole2
      vars:
        name: John
        born: 1970
```

### Including Roles

`include_role` runs a role as a task, at that point of the task list. It is **dynamic**: decided at runtime,
so it can be used with `when` and `loop`.

```yaml
---
- name: Including Roles
  hosts: webservers
  tasks:
    - name: Print a message
      ansible.builtin.debug:
        msg: "this task runs before the role"

    - name: Include the deploy-web-server role
      ansible.builtin.include_role:
        name: deploy-web-server
      vars:
        web_title: "Hello"
      when: ansible_facts['distribution'] == 'Fedora'

    - name: Print a message
      ansible.builtin.debug:
        msg: "this task runs after the role"
```

### Importing Roles

`import_role` is similar, but it is **static**: pre-processed at Playbook parsing time, not at execution time.
Its `when` and `vars` are copied onto every task of the imported Role.

```yaml
    - name: Import the deploy-web-server role
      ansible.builtin.import_role:
        name: deploy-web-server
```

| Feature | import_role / import_tasks | include_role / include_tasks |
|---------|-------------|--------------|
| Processed | Static, at parsing | Dynamic, at runtime |
| `when` and `vars` | Applied to every imported task | Applied to the include itself |
| With `loop` | Not supported | Supported |
| `--list-tasks`, `--start-at-task` | See the imported tasks | Don't see the included tasks |
| Usage | Simple static inclusion | Dynamic, conditional and looped inclusion |

The same applies to task files (`import_tasks` / `include_tasks`). Whole Playbooks can only be imported:
`ansible.builtin.import_playbook` (see `vsftpd/site.yml`).

---
## Exercises

| Directory | What it shows |
|-----------|---------------|
| [deploy-web](deploy-web/) | A small role with `defaults`, `vars`, `templates`, `handlers`, used via `include_role` |
| [vsftpd](vsftpd/README.md) | A multi-Playbook project (`site.yml` + `import_playbook`) without roles |
| [vsftpd-role](vsftpd-role/README.md) | **Step by step**: the vsftpd project converted into a role |

```bash
cd deploy-web
ansible-playbook deploy-web.yml
curl http://host1
```

> [!NOTE]
> `deploy-web` installs Apache httpd on port 80 and stops nginx/lighttpd from earlier lessons on the same port.

---
## Ansible Galaxy

[Ansible Galaxy](https://galaxy.ansible.com) is the public hub of community **roles** and **collections**
(collections bundle modules, plugins and roles, e.g. `ansible.posix`, `community.general`).

```bash
ansible-galaxy role search ntp                       # search roles
ansible-galaxy role install geerlingguy.ntp          # install into ~/.ansible/roles
ansible-galaxy role list
ansible-galaxy collection list                       # collections installed with the ansible package
ansible-galaxy collection install community.general  # install/upgrade a collection
```

In a project, list the roles and collections it needs in a `requirements.yml` file and install them all at once
(see [galaxy/requirements.yml](galaxy/requirements.yml)):

```yaml
---
roles:
  - name: geerlingguy.ntp
  - name: git_role
    src: https://github.com/geerlingguy/ansible-role-git.git
    scm: git

collections:
  - name: ansible.posix
    version: ">=1.5.0"
  - name: community.general
```

```bash
cd galaxy
ansible-galaxy install -r requirements.yml
```

> [!NOTE]
> Galaxy needs internet access (galaxy.ansible.com, github.com). In companies an internal Automation Hub or Git
> server usually serves as the source; `requirements.yml` works the same way with internal URLs.

Review roles before using them, pin their versions, and keep a validated copy (or a mirror) in-house.

---
## Linux System Roles

The Linux System Roles (on RHEL: RHEL System Roles) are supported roles for common OS configuration tasks:
`timesync`, `network`, `firewall`, `selinux`, `storage`, `logging`, `sshd`, ...

```bash
sudo dnf install -y linux-system-roles          # on RHEL: rhel-system-roles
ls /usr/share/ansible/collections/ansible_collections/fedora/linux_system_roles/roles/
```

They are configured purely with variables, e.g. [galaxy/timesync.yml](galaxy/timesync.yml):

```yaml
---
- name: Configure time synchronization with a System Role
  hosts: myhosts
  become: true
  vars:
    timesync_ntp_servers:
      - hostname: 2.fedora.pool.ntp.org
        pool: true
        iburst: true

  roles:
    - fedora.linux_system_roles.timesync
```

(The same caution applies as in [09-chrony](../14_LinuxAdminLabs/09-chrony/README.md): time sync in containers
touches the host clock.)
