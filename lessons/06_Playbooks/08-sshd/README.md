# Sshd

### In this lesson the following subjects are covered

1. Query a service's state without changing it with `check_mode`
1. Use `systemd` instead of `shell` to inspect a service
1. Read detailed unit status fields from the registered result
1. Print a multi-line summary with inline Jinja2 expressions

<img width="2720" height="1340" alt="sshd_status_flow" src="https://github.com/user-attachments/assets/e5e29bd0-a705-4a22-9582-df7586f06e16" />

---
## Query a service's state without changing it

`ansible.builtin.systemd` is the proper module for managing services under systemd — unlike calling `systemctl` through `shell` (as in lesson 03), it understands the service's state natively and only reports `changed` when it actually had to do something.

Here `state: started` would normally ensure `sshd` is running, starting it if necessary. Adding `check_mode: true` on the task itself forces it to run in dry-run mode regardless of how the Playbook was invoked, so it only reports what it finds — it never actually starts, stops or restarts the service.

---
## Read detailed unit status fields from the registered result

Where the `shell` approach in lesson 03 only gave you a single string like `active` or `inactive`, `ansible.builtin.systemd` registers a much richer `status` dictionary, mirroring the fields `systemctl show` would print — `ActiveState`, `UnitFileState`, `LoadState`, and more. This is generally the more informative way to inspect a service's state.

#### sshd.yml
```yaml
---
- name: Check if sshd service is running
  hosts: all
  become: false
  gather_facts: no

  tasks:

    - name: Check if sshd service is running
      ansible.builtin.systemd:
        name: sshd
        state: started
      register: sshd_status
      check_mode: true

    - name: Display sshd service status
      ansible.builtin.debug:
        msg: |
          SSH daemon (sshd) service status:
          - Service is running: {{ sshd_status.status.ActiveState == 'active' }}
          - Service state: {{ sshd_status.status.ActiveState }}
          - Service enabled: {{ sshd_status.status.UnitFileState == 'enabled' }}
          - Service loaded: {{ sshd_status.status.LoadState == 'loaded' }}
```

---
## Print a multi-line summary with inline Jinja2 expressions

The `|` block scalar in `msg` keeps the message spread over several readable lines. Each line embeds its own `{{ ... }}` expression, and a couple of them — `sshd_status.status.ActiveState == 'active'` — evaluate a comparison rather than just printing a raw field, turning the raw status string into a plain `True`/`False` answer to "is it running?".

---
## Running the Playbook

```bash
ansible-playbook sshd.yml
```
