# Stat

### In this lesson the following subjects are covered

1. Set up different starting conditions per host with `inventory_hostname`
1. Check whether a file exists with `stat`
1. Branch on the result with `when`
1. Override a variable from the command line with `-e`
1. Read file type, size and permissions from `stat`

<img width="2720" height="1760" alt="stat_file_check_flow" src="https://github.com/user-attachments/assets/6e5d46a9-9978-4d2a-b9ac-50f2ee3ed06b" />

---
## Set up different starting conditions per host

`inventory_hostname` is a magic variable holding the current Managed Host's name, so `when: inventory_hostname == 'host1'` restricts a task to that one host. This Play uses it to deliberately create three different starting conditions before checking for the file: `host1` gets the file touched into existence, `host2` gets it copied in from the Control Node, and `host3` has it removed — so all three outcomes of the later `stat` check can be observed in the same run.

---
## Check whether a file exists with stat

`ansible.builtin.stat` gathers everything the operating system knows about a path — without changing anything — and returns it as a dictionary of facts on `.stat`. The dictionary's most commonly used key is `exists`, a boolean.

```yaml
    - name: Check if a file exists
      ansible.builtin.stat:
        path: "{{ myfile }}"
      register: result_stat
```

---
## Branch on the result with when

Once registered, `result_stat.stat.exists` can drive `when` conditions on later tasks, printing a different message depending on whether the file was present or not.

#### exists.yml
```yaml
---
- name: Check file exists
  hosts: all
  become: false
  gather_facts: false
  vars:
    myfile: /home/devops/file.txt

  tasks:

    - name: Create file.txt only on host1
      ansible.builtin.file:
        path: /home/devops/file.txt
        state: touch
        owner: devops
        group: devops
        mode: '0644'
      when: inventory_hostname == 'host1'

    - name: Copy file.txt only to host2
      ansible.builtin.copy:
        src: ./file.txt
        dest: /home/devops/file.txt
        owner: devops
        group: devops
        mode: '0644'
      when: inventory_hostname == 'host2'

    - name: Remove file.txt from host3
      ansible.builtin.file:
        path: /home/devops/file.txt
        state: absent
      when: inventory_hostname == 'host3'

    - name: Check if a file exists
      ansible.builtin.stat:
        path: "{{ myfile }}"
      register: result_stat

    - name: Report file exists
      ansible.builtin.debug:
        msg: "The file {{ myfile }} exist"
      when: result_stat.stat.exists

    - name: Report file not exists
      ansible.builtin.debug:
        msg: "The file {{ myfile }} doesn't exist"
      when: not result_stat.stat.exists
```

---
## Running the Playbook

```bash
ansible-playbook exists.yml
```

Watch the output: `host1` and `host2` report the file exists, `host3` reports it doesn't.

---
## Override a variable from the command line

A `vars:` value is just a default — pass `-e` (`--extra-vars`) on the command line to override it for a single run, without editing the Playbook. Extra vars always win over every other variable source, which is why `target_path` is commented as overridable this way.

```bash
ansible-playbook -e target_path=/etc/passwd stat.yml
```

---
## Read file type, size and permissions from stat

Besides `exists`, the `stat` dictionary carries the file's type (`isdir`, `isreg` for a regular file, and more), `size` in bytes, `mode` (permission bits), and ownership (`pw_name`, `gr_name`). `follow: false` means a symlink itself is inspected rather than the target it points to. Every field is wrapped in `| default(...)` so the Play doesn't error out on a path that turns out not to exist, where those keys would otherwise be missing entirely.

#### stat.yml
```yaml
---
- name: Check file existence and attributes
  hosts: all
  gather_facts: false
  become: false

  vars:
    # Override with 'ansible-playbook -e target_path=<path>'
    target_path: "/etc/hosts"

  tasks:

    - name: Stat target path
      ansible.builtin.stat:
        path: "{{ target_path }}"
        follow: false
      register: stat_result
      changed_when: false
      check_mode: false

    - name: Show stat summary
      ansible.builtin.debug:
        msg:
          path: "{{ target_path }}"
          exists: "{{ stat_result.stat.exists | default(false) }}"
          is_directory: "{{ stat_result.stat.isdir | default(false) }}"
          is_file: "{{ stat_result.stat.isreg | default(false) }}"
          size_bytes: "{{ stat_result.stat.size | default(0) }}"
          mode: "{{ stat_result.stat.mode | default('') }}"
          owner: "{{ stat_result.stat.pw_name | default('') }}"
          group: "{{ stat_result.stat.gr_name | default('') }}"

    - name: Report when target does not exist
      ansible.builtin.debug:
        msg: "Target does not exist: {{ target_path }}"
      when: not stat_result.stat.exists | default(false)

    - name: Report when target is a directory
      ansible.builtin.debug:
        msg: "Target is a directory: {{ target_path }}"
      when: stat_result.stat.isdir | default(false)

    - name: Report when target is a regular file
      ansible.builtin.debug:
        msg: "Target is a regular file: {{ target_path }}"
      when: stat_result.stat.isreg | default(false)
```

---
## Running the Playbook

```bash
ansible-playbook stat.yml
```
