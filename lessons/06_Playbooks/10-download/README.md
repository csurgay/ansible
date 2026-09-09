# Download

### In this lesson the following subjects are covered

1. Target a single host with `hosts`
1. Download a file with `get_url`
1. Verify integrity with a checksum
1. Set ownership and permissions on the downloaded file

---
## Target a single host with hosts

So far every Play in this section has run against `hosts: all` or `myhosts`. Here `hosts: host1` restricts the entire Play to just that one Managed Host — useful whenever a task only needs to happen on a single machine rather than the whole inventory group.

---
## Download a file with get_url

`ansible.builtin.get_url` downloads a file from `url` straight onto the Managed Host at `dest`, acting like `curl` or `wget` wrapped as an idempotent Ansible task: if the destination file already exists and matches, it won't be downloaded again.

---
## Verify integrity with a checksum

`checksum` lets `get_url` confirm the downloaded file is exactly what was expected before keeping it. The format is `<algorithm>:<value or URL>` — here `sha256:https://.../ansible-2.9.27.tar.gz.sha` points at a URL, so Ansible fetches the expected hash from that separate `.sha` file first and compares it against what it actually downloaded, failing the task if they don't match.

#### download.yml
```yaml
---
- name: File download
  hosts: host1
  become: false
  gather_facts: false
  vars:
    myurl: "https://releases.ansible.com/ansible/ansible-2.9.27.tar.gz"
    mycrc: "sha256:https://releases.ansible.com/ansible/ansible-2.9.27.tar.gz.sha"
    mydest: "/home/devops"

  tasks:

    - name: File Download
      ansible.builtin.get_url:
        url: "{{ myurl }}"
        dest: "{{ mydest }}"
        checksum: "{{ mycrc }}"
        owner: devops
        group: devops
        mode: '0644'
```

---
## Set ownership and permissions on the downloaded file

Just like `copy`, `get_url` accepts `owner`, `group` and `mode` to set the downloaded file's permissions in the same task — no separate `file` task is needed afterwards.

---
## Running the Playbook

```bash
ansible-playbook download.yml
```
