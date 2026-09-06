# Ansible Bootcamp Cheatsheet

*Compiled from all 18 lesson modules (`YourFirstPlaybook` → `17_Tags`)*

---

## 1. CLI Commands

| Command | Common usage |
|---|---|
| `ansible --version` | Show Ansible/core version, config file, module path, Python/Jinja version |
| `ansible all --list-hosts` / `-i <inv>` | List hosts resolved from inventory (`*pattern*`, `db*`, etc. supported) |
| `ansible <pattern> -m <module> -a "<args>"` | Ad-hoc command against a host pattern |
| `ansible all --become --ask-become-pass -m shell -a whoami` | Ad-hoc with privilege escalation, prompting for sudo pass |
| `ansible --help` | CLI flag reference (`-i`, `-l`, `-m`, `-o`, `-t`, `-v`) |
| `ansible-playbook <play>.yml` | Run a playbook |
| `ansible-playbook <play>.yml -i <inv>` | Run with a specific inventory |
| `ansible-playbook <play>.yml --tags "a,b"` | Run only tasks/plays/roles tagged `a` or `b` |
| `ansible-playbook <play>.yml --skip-tags "a"` | Run everything except tagged `a` |
| `ansible-playbook <play>.yml --list-tags` | List all tags defined in a playbook |
| `ansible-playbook <play>.yml --ask-vault-pass` | Prompt for Vault password at run time |
| `ansible-playbook <play>.yml --vault-id=@prompt` | Prompt via named vault-id |
| `ansible-playbook <play>.yml --vault-pass-file=<f>` | Read vault password from file |
| `ansible-inventory -i <inv> --list` / `--graph` | Inspect resolved inventory structure |
| `ansible-config list` / `dump` / `view` / `validate` | List all settings / show effective config / show file / validate |
| `ansible-doc -l` | List all installed modules |
| `ansible-doc -s <module>` | Show module snippet/syntax |
| `ansible-vault create/edit/view/decrypt/rekey <file>` | Manage encrypted files |
| `ansible-vault decrypt <file> --output=<f>` | Decrypt to a new file |
| `ansible-galaxy role init <name>` | Scaffold a new role directory structure |
| `ansible-galaxy collection install <ns.collection>` | Install a collection (e.g. `kubernetes.core`) |
| `ansible-lint` | Lint playbooks/roles against best practices |

**Useful ad-hoc modules:** `ping`, `command`, `shell`, `copy`, `fetch`, `file`, `package`, `yum`, `service`, `systemd`, `reboot`, `setup`, `user`, `debug`

---

## 2. Modules Used Across the Course

| Category | Modules |
|---|---|
| Connectivity / facts | `ping`, `setup`, `debug`, `stat`, `group_by` |
| Package management | `yum`, `dnf`, `apt`, `package` |
| Service management | `service`, `systemd`, `reboot`, `firewalld`, `timezone` |
| Files & content | `copy`, `file`, `template`, `get_url`, `fetch` |
| Users | `user` |
| Execution | `command`, `shell` |
| Source control | `git` |
| Web/API | `uri` |
| Roles/includes | `include_role`, `import_tasks` |
| Kubernetes (collection) | `kubernetes.core.k8s` (namespaces, pods, deployments, configmaps) |

> Fully-qualified collection names (FQCN) appear throughout, e.g. `ansible.builtin.debug`, `ansible.builtin.template`, `ansible.builtin.dnf` — same modules, namespaced form (best practice per `ansible-lint`).

---

## 3. Inventory

```ini
[controlnode]
localhost

[webservers]
webhost1
webhost2

[databases]
dbhost1 ansible_host=192.168.1.17

[everyone:children]
webservers
databases
```
- `ansible_host`, `ansible_user`, `ansible_connection`, `ansible_port` — per-host connection vars
- Multiple inventories: `-i file1,file2` or point `ansible.cfg` at a directory

## 4. ansible.cfg essentials

```ini
[defaults]
inventory = ./hosts_inventory
remote_user = devops
ask_pass = false

[privilege_escalation]
become = true
become_method = sudo
become_user = root
become_ask_pass = true
```

## 5. Playbook Skeleton

```yaml
- name: Play name
  hosts: webservers
  become: true
  vars:
    my_var: value
  tasks:
    - name: Install httpd
      ansible.builtin.yum:
        name: httpd
        state: latest
      tags: [webserver]
```

## 6. Variables & Jinja2

- Define in `vars:`, `group_vars/`, `host_vars/`, `defaults/main.yml` (role), or `-e` on CLI
- Reference: `{{ my_var }}`, `{{ item }}`, `{{ item.name }}`, `{{ dictionary['key'] }}`, `{{ list_var[0] }}`
- Special vars: `inventory_hostname`, `ansible_hostname`, `ansible_facts`, `hostvars[host]`, `groups['webservers']`
- Filters: `{{ ansible_port | default('22') }}`

## 7. Control Flow

| Keyword | Purpose |
|---|---|
| `when:` | Conditional execution |
| `loop:` / `with_items:` | Iterate over a list |
| `register:` | Capture task output |
| `until:` / `retries:` / `delay:` | Retry loop |
| `changed_when:` / `failed_when:` | Override task status |
| `ignore_errors:` | Continue past task failure |
| `block:` / `rescue:` / `always:` | Try/except/finally grouping |
| `notify:` + `handlers:` | Trigger a handler on change |

## 8. Facts

```bash
ansible all -m setup                          # dump all facts
ansible localhost -m debug -a 'var=hostvars.host3.ansible_facts'
```
Key facts: `ansible_facts['distribution']`, `ansible_hostname`, `ansible_connection`, network facts under `ansible_facts['eth0']['ipv4']['address']`

## 9. Vault

```bash
ansible-vault create mysecrets.yml
ansible-vault edit mysecrets.yml
ansible-vault view mysecrets.yml
ansible-vault decrypt mysecrets.yml --output=plain.yml
ansible-vault rekey mysecrets.yml
ansible-playbook site.yml --ask-vault-pass
```

## 10. Templates (Jinja2, `.j2`)

```yaml
- name: Deploy config from template
  ansible.builtin.template:
    src: app.conf.j2
    dest: /etc/app/app.conf
```
Template files use the same `{{ var }}`, `{% if %}`, `{% for %}` Jinja2 syntax as playbooks.

## 11. Roles

```
roles/
  webserver/
    tasks/main.yml
    handlers/main.yml
    templates/
    files/
    vars/main.yml
    defaults/main.yml
    meta/main.yml
```
```bash
ansible-galaxy role init webserver
```
Use via `roles:` list in a play, or `include_role:` / `import_role:` mid-task-list.

## 12. Tags

```yaml
tasks:
  - name: Install dependencies
    apt: { name: git, state: present }
    tags: [install, webserver]
```
```bash
ansible-playbook site.yml --tags "webserver"
ansible-playbook site.yml --skip-tags "backup"
ansible-playbook site.yml --list-tags
```
Best practice: 2–3 tags per task max, descriptive names (`install_apache`, not `task1`).

## 13. Kubernetes (kubernetes.core)

```bash
ansible-galaxy collection install kubernetes.core
pip install kubernetes
```
```yaml
- name: Create namespace
  kubernetes.core.k8s:
    api_version: v1
    kind: Namespace
    name: myapp
    state: present
```
Also used for Pods, Deployments, and ConfigMaps via the same `k8s` module with different `definition:`/`kind:` blocks.
