# CLI Tools

It this section we explore a number CLI (Command Line Interface) tools coming with the Ansible package.

---
## CLI toolset

There are other CLI tools than `ansible` installed from the package, see the list below. Some
of them can also be used for smoke testing or quickly query or manage a single aspect of target 
hosts without writing a full Playbook.

| CLI tool | Purpose |
|----------|---------|
| ansible | Runs single Task on managed hosts (aka ad-hoc command ) |
| ansible-config | View, init, validate an Ansible Configuration |
| ansible-console | Interactive Ansible command interpreter |
| ansible-doc | Modules and Plugins documentation tool (snippet|
| ansible-galaxy | Roles and Collections related operations |
| ansible-inventory | View actual Inventory groups, hosts, and variables |
| ansible-playbook | Run Playbook on managed hosts |
| ansible-pull | Pulls Playbook from git repo and runs on managed hosts |
| ansible-vault | Secret variable and file encryption automatism for Playbooks |

### Testing the tools

A few typical uses of the other CLI tools:

- `ansible-config view`
- `ansible-config validate`
- `ansible-config list | grep -A6 LOG_PATH`
- `ansible-console all`
  - ```
    list
    list goups
    ping
    help ansible.builtin.debug
    command date
    command hostname
    become true
    dnf name=sl state=present
    set_fact alma=2kg
    debug var=alma
    gather_facts
    debug var=ansible_facts.os_family
    ```
- `ansible-doc debug`
- `ansible-doc --snippet debug`
- `ansible-galaxy role install system`
- `ansible-galaxy role list`
- `ansible-inventory --list --vars`
- `ansible-inventory --graph`
- `ansible-playbook --inventory targethosts --become --aks-become-pass myplaybook.yml`
- `ansible-pull -U https://github.com/user/myansible myplaybook.yml`
- `ansible-vault view --vault-id=@prompt mysecret.yml`

---
## Additional CLI tools

#### ansible-galaxy

We used `ansible-galaxy` to init empty Roles boilerplate directory structure. Try:

```bash
ansible-galaxy
ansible-galaxy role
ansible-galaxy role --help
ansible-galaxy role list
ansible-galaxy role search selinux
ansible-galaxy role search ntp
ansible-galaxy role search linux-system-roles

sudo dnf install linux-system-roles
(same as rhel-system-roles)
ansible-galaxy role list
ls -la /usr/share/ansible/roles

ansible-galaxy collection list
```

#### ansible-lint

Try:

```bash
sudo dnf install ansible-lint
ansible-lint --help
ansible-lint <playbook file>
ansible-lint <playbook project directory>
```
