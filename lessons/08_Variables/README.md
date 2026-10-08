# Section 8. Variables

### In this section the following subjects will be covered:

1. Variable names
1. Usage
1. Registered variables
1. Nested (complex) variables
1. Variable Precedence
1. Magic variables
1. Connection variables
1. Prompt variables
1. Exercises

---
### Variable names

+ Only letters, numbers and underscores
+ Cannot redefine keywords and internal variables
+ Cannot start with a number

---
### Usage

#### Define

```yaml
my_var: 123
other: "string with spaces"
path_variable: /etc/ansible/hosts
list_var:
  - first
  - second
  - third
dictionary:
  name: John
  born: 1970
```

#### Reference (Jinja2 syntax)

```yaml
message: Value of other is {{ other }}.
quoted_if_starts_with: "{{ my_var }}"
list_item: "{{ list_var[0] }}"
name_born: "{{ dictionary['name'] }}:{{ dictionary['born'] }}"

# Value of other is string with spaces.
# 123
# first
# John:1970
```

A value that **starts** with `{{` must be quoted, otherwise YAML would read the `{` as the start of a dictionary.

---
### Registered variables

The output of an Ansible Task can be saved into a variable (registering into a variable) with the `register: <var>` keyword. These newly created variables can later be tested for the success or the result of a Task's execution.

```yaml
- name: Illustration of register
  ansible.builtin.command:
    cmd: date
  register: date_result
```

#### Best practice for registered variables

- **Descriptive variable names**

Use clear and meaningful names when you create registered variables in your playbooks. This helps you and your teammates quickly understand what each variable contains. For example, names like `disk_usage_output` or `nginx_status` are much better than generic ones like `result` or `output`.

- **Avoid overusing registered variables**

Only register output when you actually need the data for later tasks. Storing unnecessary results can make your playbook harder to read and add clutter to the task output. A clean playbook is easier to understand, debug, and maintain.

- **Use debug for troubleshooting**

When developing a playbook, use the debug module to print the contents of a registered variable. This helps you see the variable’s structure and make sure you’re using the right attributes in your conditions or loops. You can add and remove these debug tasks as needed during development.

- **Handle failures**

If a task might fail but you still want the playbook to continue, register its result and decide yourself what counts as failure with `failed_when:` (or, less precisely, `ignore_errors: true`). Later tasks can then test the registered result, e.g. `when: result.rc != 0` or `when: result is failed`. See [12_ControlFlow](../12_ControlFlow/README.md).

---
### Nested (complex) variables

If a query or calculation returns a nested (complex) object in a variable, the structure can be unnested in two ways:

+ Bracket notation (`ansible_facts['python']['version']['major']`)
+ Dot notation (`ansible_facts.python.version.major`)

Bracket notation always works, dot notation fails for keys that contain `-` or clash with Python method names (e.g. `items`, `keys`).

---
### Variable Precedence

> [!WARNING]
> Variables with the same name can be defined in 20+ different places of the Ansible ecosystem. They override each other according to their location: this is Variable Precedence.

> [!TIP]
> Keep it simple. Define each variable in only one place, so that precedence never matters.

Variables can be defined in several places, e.g.:

+ Roles
+ Inventory
+ Playbooks/Plays
+ Included files
+ Command line

Ansible loads all of them and the one with the higher precedence wins.

#### Inventory variables

Precedence from lowest to highest:

- `all`
- parent group
- child group
- host

#### world_inventory

```ini
washington

[france]
paris myvar="host_highest"

[germany]
hamburg
hannover

[europe:children]
france
germany

[europe:vars]
myvar="child_group"

[china]
beijing
shanghai

[asia:children]
china

[world:children]
europe
asia

[world:vars]
myvar="parent_group"

[all:vars]
myvar="all_lowest"
```

#### In yaml format

```bash
ansible-inventory -i ./world_inventory --list --yaml
```

#### outputs

```yaml
all:
  children:
    ungrouped:
      hosts:
        washington:
          myvar: all_lowest
    world:
      children:
        asia:
          children:
            china:
              hosts:
                beijing:
                  myvar: parent_group
                shanghai:
                  myvar: parent_group
        europe:
          children:
            france:
              hosts:
                paris:
                  myvar: host_highest
            germany:
              hosts:
                hamburg:
                  myvar: child_group
                hannover:
                  myvar: child_group
```

#### In JSON format

```bash
ansible-inventory -i ./world_inventory --list
```

#### outputs

```json
{
    "_meta": {
        "hostvars": {
            "beijing": {
                "myvar": "parent_group"
            },
            "hamburg": {
                "myvar": "child_group"
            },
            "hannover": {
                "myvar": "child_group"
            },
            "paris": {
                "myvar": "host_highest"
            },
            "shanghai": {
                "myvar": "parent_group"
            },
            "washington": {
                "myvar": "all_lowest"
            }
        }
    },
    "all": {
        "children": [
            "ungrouped",
            "world"
        ]
    },
    "asia": {
        "children": [
            "china"
        ]
    },
    "china": {
        "hosts": [
            "beijing",
            "shanghai"
        ]
    },
    "europe": {
        "children": [
            "france",
            "germany"
        ]
    },
    "france": {
        "hosts": [
            "paris"
        ]
    },
    "germany": {
        "hosts": [
            "hamburg",
            "hannover"
        ]
    },
    "ungrouped": {
        "hosts": [
            "washington"
        ]
    },
    "world": {
        "children": [
            "europe",
            "asia"
        ]
    }
}
```

#### Play variables

```yaml
---
- name: Play variable illustration
  hosts: all
  gather_facts: false
  vars:
    myvariable: "Something for this Play only"
    another: 1234
```

#### Included variables

```yaml
---
- name: Include vars_files illustration
  hosts: all
  gather_facts: false
  vars:
    hardcoded: "here"
  vars_files:
    - vars/reusable_variables.yml
    - vars/another_varfile.yml
```

Relative paths are relative to the Playbook.

#### Format of vars_files

```yaml
---
# Variables for use in multiple Plays
myvariable: "Reusable string"
another: 1234
```

#### Precedence of variable locations

From lowest to highest (simplified from the
[official list](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_variables.html#understanding-variable-precedence)):

1. Role defaults (`roles/x/defaults/main.yml`)
1. Inventory file group vars (`[group:vars]`)
1. Inventory `group_vars/all`
1. Playbook `group_vars/all`
1. Inventory `group_vars/*`
1. Playbook `group_vars/*`
1. Inventory file host vars (`host1 myvar=...`)
1. Inventory `host_vars/*`
1. Playbook `host_vars/*`
1. Host facts and cached `set_fact`
1. Play `vars`
1. Play `vars_prompt`
1. Play `vars_files`
1. Role vars (`roles/x/vars/main.yml`)
1. Block `vars`
1. Task `vars`
1. `include_vars`
1. Registered vars and `set_fact`
1. Role (and `include_role`) params
1. Include params
1. Extra vars on the command line (`-e "var1=John var2=123"`), they always win

"Inventory `group_vars`" is a `group_vars/` directory next to the inventory file, "Playbook `group_vars`" is a
`group_vars/` directory next to the Playbook:

```
ansible_project/
├── ansible.cfg
├── inventory/
│   ├── prod.ini           <- inventory file (host vars, [group:vars])
│   ├── group_vars/        <- inventory group_vars
│   │   └── myhosts
│   └── host_vars/         <- inventory host_vars
│       └── host1
├── group_vars/            <- playbook group_vars
│   └── myhosts
├── host_vars/             <- playbook host_vars
│   ├── host1
│   └── host2
├── playbook1.yml          <- play vars, vars_files, vars_prompt, block vars, task vars,
│                             include_vars, registered vars, set_fact
├── playbook2.yml
└── roles/
    ├── mariadb/
    │   ├── defaults/main.yml   <- role defaults (lowest)
    │   ├── vars/main.yml       <- role vars
    │   ├── templates/          <- *.j2 files
    │   └── tasks/main.yml
    └── nginx/
        ├── defaults/main.yml
        ├── vars/main.yml
        ├── templates/
        └── tasks/main.yml
```

> [!NOTE]
> The above directory layout is best practice, where Playbooks map a set of Roles to a set of Inventory hosts.
> See also [09_DirectoryLayout](../09_DirectoryLayout/README.md).

> [!TIP]
> Avoid precedence conflicts by planning variable placement, and by naming variables differently
> (e.g. prefix role variables with the role name: `nginx_port`, `mariadb_port`).

---
### Magic variables

Magic variables are automatically set by Ansible and can be used to get information specific to a particular managed host.

#### Most used Magic variables:

| Magic variable | Description |
|----------------|-------------|
| **`hostvars`** | Variables of all hosts, indexed by host name, e.g. `hostvars['host2']`. Includes facts once they are gathered |
| **`group_names`** | All the groups the current managed host is member of |
| **`groups`** | All groups of the inventory with their hosts, e.g. `groups['webservers']` |
| **`inventory_hostname`** | Name of the current managed host as written in the inventory |
| **`ansible_play_hosts`** | Hosts of the current Play that are still active |

#### Usage examples

```bash
ansible host1     -m debug -a 'var=hostvars["host2"]'
ansible host2     -m debug -a 'var=hostvars'
ansible all       -m debug -a 'var=hostvars.host3.ansible_version.string'
ansible host1     -m debug -a 'var=group_names'
ansible localhost -m debug -a 'var=groups'
ansible host1     -m debug -a 'var=inventory_hostname'
```

---
### Connection variables

Connection variables are placed into the inventory to control how Ansible connects to hosts individually. They default to the settings of `ansible.cfg` (or Ansible's built-in defaults).

#### Most used Connection variables:

| Connection variable | Description |
|---------------------|-------------|
| **`ansible_host`** | The address to connect to, if it differs from the inventory name (default: `inventory_hostname`) |
| **`ansible_port`** | SSH port if not 22 (default: `remote_port` in `ansible.cfg`, or 22) |
| **`ansible_user`** | User to log in with (default: `remote_user` in `ansible.cfg`, or the current user) |
| **`ansible_become`** | Same as `--become` for this host (default: `become` in `ansible.cfg`) |
| **`ansible_become_user`** | Same as `--become-user` for this host (default: root) |
| **`ansible_connection`** | Connection plugin: `ssh` (default), `local`, `podman`, ... |

#### Sample Inventory usage

```ini
[testnode]
localhost

[application]
frontend ansible_host=host1 ansible_user=devops ansible_become=true
backend ansible_host=host2
appserver ansible_host=host3
```

#### Sample Playbook usage

```yaml
# Playbook to illustrate inventory_hostname vs. ansible_host
---
- name: inventory_hostname vs. ansible_host
  hosts: all
  become: false
  gather_facts: false

  tasks:

    - name: Print hostnames
      ansible.builtin.debug:
        msg: |
          {{ inventory_hostname }} is {{ ansible_host }}:{{ ansible_port | default('22') }}
          {{ ansible_user | default('n/a') }} {{ ansible_connection }}
```

---
### Prompt variables

```yaml
---
- name: Prompt variables
  hosts: host1
  gather_facts: false
  vars_prompt:
    - name: username
      prompt: What is your username?
      private: false
    - name: password
      prompt: What is your password?
      private: true  # default is true
    - name: packagename
      prompt: What would you like to install?
      private: false

  tasks:

    - name: Print a message
      ansible.builtin.debug:
        msg: 'Username:{{ username }} Password:{{ password }} <- bad practice'

    - name: Install packagename
      ansible.builtin.dnf:
        name: "{{ packagename }}"
        state: present
```

---
### Exercises

All files are in this directory. Run them from here, `ansible.cfg` points at `host_inventory`.

| File | Run with | What to look at |
|------|----------|-----------------|
| `test.yml` | `ansible-playbook test.yml` | Defining and referencing variables of different types |
| `register.yml` | `ansible-playbook register.yml` | `register` and using the result |
| `nested.yml` | `ansible-playbook nested.yml` | Bracket vs dot notation on facts |
| `prompt.yml` | `ansible-playbook prompt.yml` | `vars_prompt` (try `sl` or `tree` as package) |
| `world_inventory` | `ansible-inventory -i world_inventory --graph --vars` | Inventory variable precedence |
| `hostnames.yml` | `ansible-playbook -i app_inventory hostnames.yml` | `inventory_hostname` vs `ansible_host` |
| `pass_variable.yml` | `ansible-playbook -i pass_inventory pass_variable.yml` | Play vars live in one Play only, facts stay with their host (`hostvars`) |

#### Precedence exercise

`precedence/` defines `myvar` for `host1` in six places. **Predict** the printed values before running!

| File | Location | Value |
|------|----------|-------|
| `inventory/prod.ini` `[myhosts:vars]` | inventory file group var | 12 |
| `inventory/prod.ini` `host1 myvar=13` | inventory file host var | 13 |
| `group_vars/myhosts` | playbook group_vars | 14 |
| `host_vars/host1` | playbook host_vars | 15 |
| `roles/myrole/defaults/main.yml` | role defaults | 10 |
| `roles/myrole/vars/main.yml` | role vars | 16 |

```bash
cd precedence
ansible-playbook playbook.yml                # Play 1 prints?  Play 2 (inside the role) prints?
ansible-playbook playbook.yml -e myvar=99    # and now?
```

<details>
<summary>Answer</summary>

Play 1 prints `15` (playbook `host_vars` beat everything from the inventory and the playbook `group_vars`),
Play 2 prints `16` (role vars beat host_vars). With `-e myvar=99` both print `99`: extra vars always win.
Now rename `host_vars/host1` to `host_vars/host1.bak` and run again: Play 1 prints `13`, because an inventory
**host** var beats any group var.

</details>
