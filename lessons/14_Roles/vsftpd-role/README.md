# vsftpd-role project

Convert vsftpd complex Playbook to a Role-based Playbook


## Copy vsftpd project as basis Role transformation

```bash
cd /home/devops/ansible-training/lessons/14-Roles/
cp -r vsftpd/ vsftpd-to-role
```

## Create empty role boilerplate directory structure

```bash
cd vsftpd-to-role
mkdir roles
cd roles
ansible-galaxy init vsftpd-role
cd ..
tree roles
```

## Place vars.yml into roles/vsftpd-role/vars directory as main.yml

```bash
mv vars/vars.yml roles/vsftpd-role/vars/main.yml
rmdir vars/
```

## Place template file into roles/vsftpd-role/template directory

```bash
mv templates/vsftpd.conf.j2 roles/vsftpd-role/templates/
rmdir templates/
```

## Place site.yml into roles/vsftpd/tasks directory as main.yml
mv site.yml roles/vsftpd-role/tasks/main.yml

## Transform this new tasks/main.yml into Role format

```bash
---
# FTP Servers playbook
- include_tasks: vsftpd.yml
  when: inventory_hostname in groups['ftpservers']
  
# FTP Clients playbook
- include_tasks: ftpclients.yml
  when: inventory_hostname in groups['ftpclients']
```

## Place the included Playbook yaml files also into roles/vsftpd/tasks/
mv vsftpd.yml ftpclients.yml roles/vsftpd-role/tasks/

## Remove from these files all Playbook details and handlers to become Tasklists

```yaml
- name: latest version of lftp is installed
  ansible.builtin.dnf:
    name: lftp
    state: latest
```

```yaml
---
    - name: Packages are installed
      ansible.builtin.dnf:
        name: "{{ vsftpd_package }}"
        state: present

    - name: Ensure service is started
      ansible.builtin.service:
        name: "{{ vsftpd_service }}"
        state: started
        enabled: true

    - name: Configuration file is installed
      ansible.builtin.template:
        src: templates/vsftpd.conf.j2
        dest: "{{ vsftpd_config_file }}"
        owner: root
        group: root
        mode: 0600
        setype: etc_t
      notify: restart vsftpd

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
        port: 21000-21020/tcp
        permanent: true
        state: enabled
        immediate: true
```

## Place the remove handler into roles/vsftpd-role/handlers/main.yml

```yaml
---
# handlers file for vsftpd-role
- name: restart vsftpd
  ansible.builtin.service:
    name: "{{ vsftpd_service }}"
    state: restarted
```

## Create test as roles/vsftpd-role/tests/main.yml

```yaml
---
    - name: Test host3.lftp to host2.vsftpd get file to host3
      ansible.builtin.shell:
        cmd: |
          lftp -u devops,devops host2<<EOF
          cd /tmp
          get -e /etc/hosts
          # -e for deleteing file before copy to make this test idempotent
          bye
          EOF
      register: result_lftp

    - name: Print debug if failed
      ansible.builtin.debug:
        var: result_lftp
      when: result_lftp is failed

    - name: Register uploadad file content
      ansible.builtin.shell:
        cmd: cat /home/devops/hosts
      register: result_cat

    - name: Print file content
      ansible.builtin.debug:
        msg: "{{ result_cat.stdout }}"
```

## Complete meta info in roles/vsftpd-role/meta/main.yml

```yaml
galaxy_info:
  author: Ansible Training
  description: Role to set up ftp servers and clients, and testing
  company: Good company :)
```

## Create a test.yml in the main Playbook directory

```yaml
---
- name: Smoke test of vsftpd-to-role project
  hosts: host3
  become: true
  gather_facts: false

  roles:
    - vsftpd-role

  tasks:

    - name: Testing
      ansible.builtin.include_tasks:
        file: roles/vsftpd-role/tests/main.yml
```

## Run the smoke test

```bash
ansible-playbook test.yml
```
