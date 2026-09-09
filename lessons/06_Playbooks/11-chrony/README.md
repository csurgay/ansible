# Chrony

> **Note:** this lesson needs to run rootful (`sudo podman ...`) or on a VM, not in a rootless container — see `RUN_THIS_ROOTFUL_OR_ON_VM_NOT_ROOTLESS_CONTAINER`. Adjusting the system clock and timezone needs privileges a rootless container's Managed Host doesn't have.

### In this lesson the following subjects are covered

1. Always install the newest package with `state: latest`
1. Deploy a config file with `template`
1. Restart a service unconditionally
1. Set the system timezone
1. Confirm the result with `shell` and `debug`

---
## Always install the newest package with state: latest

Every other lesson so far has used `state: present`, which only guarantees the package is installed — an existing older version is left alone. `state: latest` instead makes `dnf` also *upgrade* the package if a newer version is available, which for a time-sync daemon like `chrony` is a reasonable default to want.

---
## Deploy a config file with template

`ansible.builtin.template` copies `chrony.conf` to the Managed Host just like `copy` would, but first renders it through Jinja2 — so any `{{ variables }}` inside it would be substituted before delivery. This particular file happens not to use any, but `template` is still the right module to reach for whenever a config file *might* need templating, since a plain `copy` will never evaluate Jinja2 at all.

`backup: yes` saves a timestamped copy of the previous `/etc/chrony.conf` before overwriting it.

---
## Restart a service unconditionally

Unlike lesson 03's `is-active` check or lesson 04's `notify`-driven restart, this task restarts `chronyd` on every run, whether or not the config actually changed — appropriate here since simply deploying a config isn't guaranteed to be picked up without an explicit restart.

---
## Set the system timezone

`community.general.timezone` sets the Managed Host's timezone — note the `community.general` collection prefix, since this one isn't part of `ansible.builtin`. Getting the timezone right matters for chrony: a correct time source is only useful if the clock displaying it is also in the right zone.

#### chrony.yml
```yaml
---
- name: Install, config and run chrony (ntp)
  hosts: all
  become: true
  gather_facts: false

  tasks:

    - name: make sure chronyd is installed
      ansible.builtin.dnf:
        name: chrony
        state: latest

    - name: deploy chrony.conf template
      ansible.builtin.template:
        src: chrony.conf
        dest: /etc/chrony.conf
        owner: root
        group: root
        mode: 0644
        backup: yes

    - name: Restart chronyd
      ansible.builtin.service:
        name: chronyd
        state: restarted

    - name: Set timezone
      community.general.timezone:
        name: Europe/Budapest

    - name: Get date time
      ansible.builtin.shell:
        cmd: date
      register: result_date

    - name: Print date
      ansible.builtin.debug:
        var: result_date.stdout
```

---
## Confirm the result with shell and debug

The Playbook finishes by running `date` on the Managed Host and printing its output — a quick, visible way to confirm the timezone change actually took effect, right there in the Play's output.

---
## Running the Playbook

```bash
ansible-playbook chrony.yml
```
