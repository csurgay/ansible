# Raw

### In this lesson the following subjects are covered

1. Run commands without needing Python on the Managed Host with `raw`
1. Mark a task as never `changed` with `changed_when`
1. Force a task to run even in check mode with `check_mode`
1. Safely print optional output with the `default` filter

---
## Run commands without needing Python on the Managed Host

Almost every Ansible module — including `command` and `shell` — works by copying a small Python program to the Managed Host and executing it there. `ansible.builtin.raw` is the exception: it sends the command straight over SSH with no Python involved at all.

This makes `raw` the module of choice when Python isn't installed yet on the target — for example bootstrapping a brand-new minimal image, or talking to a network device — often just to install Python so that every other module can be used afterwards.

```yaml
    - name: Run uname -r using raw
      ansible.builtin.raw: uname -r
      register: result_uname
```

---
## Mark a task as never changed with changed_when

Because `raw` has no idea what the command it ran was supposed to do, Ansible has no way to tell whether anything actually changed on the Managed Host — so by default a `raw` task always reports `changed`. For a purely informational command like `uname` or `uptime`, that's misleading. Setting `changed_when: false` tells Ansible this task never counts as a change, keeping your Play's summary accurate.

---
## Force a task to run even in check mode

In `--check` (dry-run) mode, Ansible normally skips `raw` tasks, since it can't predict what they would do to the Managed Host. `check_mode: false` overrides that and makes the task always execute — appropriate here because `uname` and `uptime` are read-only and never modify system state, so running them during a dry run is safe.

#### raw.yml
```yaml
- name: Use raw to run uname and uptime
  hosts: all
  gather_facts: false
  become: false

  tasks:

    - name: Run uname -r using raw
      ansible.builtin.raw: uname -r
      register: result_uname
      changed_when: false
      check_mode: false

    - name: Show uname result
      ansible.builtin.debug:
        msg: "{{ result_uname.stdout | default('') }}"

    - name: Run uptime using raw
      ansible.builtin.raw: uptime
      register: result_uptime
      changed_when: false
      check_mode: false

    - name: Show uptime result
      ansible.builtin.debug:
        msg: "{{ result_uptime.stdout | default('') }}"
```

---
## Safely print optional output with the default filter

`{{ result_uname.stdout | default('') }}` prints `result_uname.stdout` if it exists, and falls back to an empty string instead of failing if it doesn't. This is good practice whenever a registered result might be missing an expected key — for `raw`, `stdout` is only populated when the command produced output, so the `default` filter keeps `debug` from erroring out on an undefined variable.

---
## Running the Playbook

```bash
ansible-playbook raw.yml
```
