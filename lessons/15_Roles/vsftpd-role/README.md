# vsftpd-role project

Convert the [vsftpd](../vsftpd/README.md) Playbook project into a Role-based project.
This directory contains the finished result; follow the steps below to build it yourself in a new directory.

## Copy the vsftpd project as the basis of the Role transformation

```bash
cd ~/ansible/lessons/15_Roles/
cp -r vsftpd/ my-vsftpd-role
cd my-vsftpd-role
```

## Create the empty role boilerplate directory structure

```bash
mkdir roles
cd roles
ansible-galaxy role init vsftpd-role
cd ..
tree roles
```

> [!NOTE]
> Role names with `-` work for roles in a project like this one, but roles inside collections (and Galaxy)
> require `_`: `vsftpd_role`. Prefer underscores in new roles.

## Place vars.yml into roles/vsftpd-role/vars as main.yml

```bash
mv vars/vars.yml roles/vsftpd-role/vars/main.yml
rmdir vars/
```

## Place the template into roles/vsftpd-role/templates

```bash
mv templates/vsftpd.conf.j2 roles/vsftpd-role/templates/
rmdir templates/
```

Inside a role, `template` and `copy` look for their `src` in the role's `templates/` and `files/` directories,
so the task refers to it simply as `src: vsftpd.conf.j2`.

## Place site.yml into roles/vsftpd-role/tasks as main.yml

```bash
mv site.yml roles/vsftpd-role/tasks/main.yml
```

## Transform this new tasks/main.yml into Role format

A role's `tasks/main.yml` is a plain **list of tasks**, not a Playbook. Playbook imports become task includes,
and the `hosts:` of the original Plays become conditions:

```yaml
---
# tasks file for vsftpd-role

# FTP servers
- name: Set up the FTP servers
  ansible.builtin.include_tasks: vsftpd.yml
  when: inventory_hostname in groups['ftpservers']

# FTP clients
- name: Set up the FTP clients
  ansible.builtin.include_tasks: ftpclients.yml
  when: inventory_hostname in groups['ftpclients']
```

> [!TIP]
> This keeps the exercise simple. In real life you would rather write **two** roles (`vsftpd_server` and
> `ftp_client`) and apply each to its own host group in the Playbook: a role should do one thing.

## Place the included Playbooks into roles/vsftpd-role/tasks

```bash
mv vsftpd.yml ftpclients.yml roles/vsftpd-role/tasks/
```

## Remove all Playbook details and the handlers to turn them into task lists

Remove `name`/`hosts`/`become`/`vars_files`/`tasks:` (the Play header), the `handlers:` section, and un-indent the
tasks. Also change the template `src:` to `vsftpd.conf.j2`.

#### roles/vsftpd-role/tasks/ftpclients.yml
```yaml
---
- name: lftp is installed
  ansible.builtin.dnf:
    name: lftp
    state: present
```

#### roles/vsftpd-role/tasks/vsftpd.yml
```yaml
---
- name: Packages are installed
  ansible.builtin.dnf:
    name: "{{ vsftpd_package }}"
    state: present

- name: Configuration file is installed
  ansible.builtin.template:
    src: vsftpd.conf.j2
    dest: "{{ vsftpd_config_file }}"
    owner: root
    group: root
    mode: '0600'
  notify: Restart vsftpd

- name: Ensure service is started
  ansible.builtin.service:
    name: "{{ vsftpd_service }}"
    state: started
    enabled: true

- name: firewalld is installed
  ansible.builtin.dnf:
    name: firewalld
    state: present

- name: firewalld is started and enabled
  ansible.builtin.service:
    name: firewalld
    state: started
    enabled: true

- name: FTP port is open
  ansible.posix.firewalld:
    service: ftp
    permanent: true
    state: enabled
    immediate: true

- name: FTP passive data ports are open
  ansible.posix.firewalld:
    port: "{{ vsftpd_pasv_min_port }}-{{ vsftpd_pasv_max_port }}/tcp"
    permanent: true
    state: enabled
    immediate: true
```

## Place the removed handler into roles/vsftpd-role/handlers/main.yml

```yaml
---
# handlers file for vsftpd-role
- name: Restart vsftpd
  ansible.builtin.service:
    name: "{{ vsftpd_service }}"
    state: restarted
```

## Create a test as roles/vsftpd-role/tests/main.yml

```yaml
---
- name: Test host3.lftp to host2.vsftpd get file to host3
  ansible.builtin.shell:
    cmd: |
      lftp -u devops,devops host2 <<EOF
      get -e /etc/hosts -o /tmp/hosts.from.host2
      bye
      EOF
  register: result_lftp
  changed_when: false

- name: Read the downloaded file
  ansible.builtin.command:
    cmd: cat /tmp/hosts.from.host2
  register: result_cat
  changed_when: false

- name: Print file content
  ansible.builtin.debug:
    msg: "{{ result_cat.stdout_lines }}"
```

`get -e` deletes an existing target file first, so the test can be repeated.

## Complete the meta info in roles/vsftpd-role/meta/main.yml and the role's README.md

```yaml
galaxy_info:
  author: Ansible Training
  description: Role to set up FTP servers and clients, and testing
  company: Good company :)
  license: MIT
```

## Create test.yml in the main project directory

The first Play applies the role to servers **and** clients, the second one runs the test on the client.

```yaml
---
- name: Apply the vsftpd role to servers and clients
  hosts: ftpservers:ftpclients
  become: true
  gather_facts: false

  roles:
    - vsftpd-role

- name: Smoke test of vsftpd-role project from the client
  hosts: ftpclients
  become: false
  gather_facts: false

  tasks:

    - name: Testing
      ansible.builtin.include_tasks:
        file: roles/vsftpd-role/tests/main.yml
```

## Run the smoke test

```bash
ansible-playbook test.yml
```
