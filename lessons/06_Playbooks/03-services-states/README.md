# Services, States

### In this lesson the following subjects are covered

1. Check the state of multiple services in a loop
1. Reuse task logic across a loop with `include_tasks`
1. Register and format looped command results
1. Suppress noisy or sensitive output with `no_log`
1. Alternative: loop over nested Ansible facts

---
## Check the state of multiple services

`ansible.builtin.shell` is looped over a list of service names, running `systemctl is-active` once per service and collecting all results into `results_state`.

`ignore_errors: true` is required here because `systemctl is-active` returns a non-zero exit code for any service that is not active — without it, Ansible would stop the Play on the first stopped or missing service.

Note that `ansible.cfg` in this project turns on `become: true` by default, but checking a service state is a read-only operation, so this Play explicitly overrides it with `become: false`.

#### states.yml
```yaml
- name: Check Multiple Services State with include_tasks
  hosts: all
  become: false
  gather_facts: false

  tasks:

    - name: Check services is-active
      ansible.builtin.shell: systemctl is-active {{ item }}
      register: results_state
      loop:
        - sshd
        - nginx
        - firewalld
      ignore_errors: true
      no_log: true

    - name: Format and print result
      include_tasks: print.yml
      loop: "{{ results_state.results }}"
      no_log: true
```

---
## Reuse task logic with include_tasks

When you `loop` over `include_tasks`, the included file is executed once per loop item, with `item` available inside it exactly as in an inline task. Here `results_state.results` is the list of per-item results produced by the looped `shell` task above, so inside `print.yml` `item` refers to one such result, not to a service name.

`item.item` gives you back the original loop value (the service name), while `item.stdout` gives you the command's output (the state, e.g. `active` or `inactive`).

#### print.yml
```yaml
---
- ansible.builtin.set_fact:
    str: "{{ item.item }} state: {{ item.stdout }}"
  no_log: true
- ansible.builtin.debug:
    var: str
```

---
## Suppress sensitive output with no_log

`no_log: true` prevents a task's arguments and results from being written to Ansible's output and logs. It's used three times in this lesson: on the `shell` task, on the `include_tasks` loop, and inside `print.yml` itself.

In real playbooks this is essential whenever a task might expose passwords, tokens, or other secrets. Here it also keeps the loop's per-iteration noise out of your terminal, so only the final `debug` output is shown.

---
## Running the Playbook

```bash
ansible-playbook states.yml
```

Since `ansible.cfg` already points `inventory` at `./host_inventory`, there's no need to pass `-i` on the command line.

---
## Alternative: loop over nested Ansible facts

The `alternative` subdirectory applies the same `include_tasks` + `loop` pattern to Ansible facts instead of shell output. `ansible.builtin.setup` gathers facts first, and the loop items — `os_family` and `default_ipv4.address` — are inserted directly into the fact name inside `print.yml` using Jinja2.

#### alternative/setup.yml
```yaml
---
- name: Gather facts
  hosts: all

  tasks:

    - name: Setup
      ansible.builtin.setup:

    - name: Print in looped include_tasks
      include_tasks: print.yml
      loop:
        - "os_family"
        - "default_ipv4.address"
```

#### alternative/print.yml
```yaml
---
- ansible.builtin.debug:
    var: ansible_facts.{{ item }}
```

---
## Running the Alternative Playbook

```bash
cd alternative
ansible-playbook -i myhosts setup.yml
```
