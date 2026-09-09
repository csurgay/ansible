# Backup

### In this lesson the following subjects are covered

1. Pull a single file back to the Control Node with `fetch`
1. Skip a host when looping with `when: inventory_hostname != ...`
1. Prepare a destination directory on the Control Node
1. Sync whole directory trees with `rsync`
1. Understand `pull` vs `push` mode in `synchronize`

<img width="2720" height="1160" alt="backup_fetch_vs_rsync_flow" src="https://github.com/user-attachments/assets/33282738-f70c-41c3-a0e3-d0bed2a2cc9e" />

---
## Pull a single file back to the Control Node

`ansible.builtin.fetch` works the opposite way to `copy`: it copies a file **from** the Managed Host **to** the Control Node, automatically nesting it under a per-host subfolder of `dest` so files from different hosts never collide. It's built for grabbing a handful of specific files — logs, configs, a single backup file — not whole directory trees.

`become: false` overrides the Play-wide `become: true` for this one task, since reading `/var/www/html/index.html` doesn't need root, and running `fetch` unprivileged avoids ending up with root-owned files on the Control Node.

---
## Skip a host when looping

`ansible_play_hosts_all` is a magic variable holding every host taking part in the Play. `inventory_hostname` is the current host being processed. `when: inventory_hostname != 'localhost'` guards the actual backup task so it only runs against the Managed Hosts, not against `controlnode` — even though `hosts: all` means the Play technically includes it too.

---
## Prepare a destination directory on the Control Node

`ansible.builtin.file` with `state: directory` creates `dest_path` if it doesn't already exist. `delegate_to: localhost` is what makes this run on the Control Node instead of the current Managed Host — without it, the directory would be created on every Managed Host instead of once, locally, where the backups actually need to land.

#### fetch.yml
```yaml
---
- name: Backup with fetch
  hosts: all
  become: true
  gather_facts: false
  vars:
    source_path: /var/www
    dest_path: /tmp/backup/fetch

  tasks:

    - name: Print all hosts
      ansible.builtin.debug:
        var: ansible_play_hosts_all
      run_once: true

    - name: Create host dir under dest_dir
      ansible.builtin.file:
        path: "{{ dest_path }}"
        state: directory
        owner: devops
        group: devops
        mode: '0755'
      delegate_to: localhost

    - name: Backup files with fetch
      ansible.builtin.fetch:
        src: "{{ source_path }}/html/index.html"
        dest: "{{ dest_path }}"
      when: inventory_hostname != 'localhost'
      become: false
```

---
## Running the Playbook

```bash
ansible-playbook fetch.yml
```

---
## Sync whole directory trees with rsync

`ansible.posix.synchronize` wraps the `rsync` command line tool, making it available as an Ansible task. Unlike `fetch`, it's built for entire directory trees, and only transfers files that actually changed since the last run, making repeated backups fast. It requires `rsync` to be installed — hence the `dnf` task at the top of this Playbook.

---
## Understand pull vs push mode in synchronize

`mode: pull` tells `synchronize` to run the transfer as if issued from the Control Node reaching out and pulling files *from* the Managed Host — the natural direction for a backup. `mode: push` (the default) does the opposite: it sends files *from* the Control Node *to* the Managed Host, which is what you'd want when deploying files out rather than backing them up.

#### rsync.yml
```yaml
---
- name: Install rsync
  hosts: all
  become: true
  gather_facts: false
  vars:
    source_path: /var/www
    dest_path: /tmp/backup/rsync

  tasks:

    - name: Install rsync
      ansible.builtin.dnf:
        name: rsync
        state: present

    - name: Print all hosts
      ansible.builtin.debug:
        var: ansible_play_hosts_all
      run_once: true

    - name: Create host dir under dest_dir
      ansible.builtin.file:
        path: "{{ dest_path }}"
        state: directory
        owner: devops
        group: devops
        mode: '0755'
      delegate_to: localhost

    - name: Backup files with rsync
      ansible.posix.synchronize:
        src: "{{ source_path }}"
        dest: "{{ dest_path }}/{{ ansible_host }}"
        mode: pull
      when: inventory_hostname != 'localhost'
      become: false
```

---
## Running the Playbook

```bash
ansible-playbook rsync.yml
```
