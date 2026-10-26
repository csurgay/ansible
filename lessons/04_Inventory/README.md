# Section 4. Inventory

### In this section the following subjects will be covered:

1. Inventory Content
1. Inventory Locations
1. Static Inventory
1. Host groups
1. Nested groups
1. Host ranges
1. Testing Inventories
1. Overriding default Inventory
1. Inventory variables
1. YAML Inventory
1. Multiple inventories
1. Dynamic Inventory

---
### Inventory Content

Inventory is a textfile listing all hosts for Ansible to potentially manage as

* hostnames,
* IP addresses,
* host groups,
* nested host groups
* host ranges

and host specific variables.

---
### Inventory Locations

Inventory can be placed into the `/etc/ansible/hosts` file, or  
into any file in the directories where we run Ansible.

This latter case is the best practice: the file is either referenced with the `-i` option,  
`ansible all -i ./inventory --list-hosts`  
or set as `inventory = ./inventory` in the project's `ansible.cfg`.

---
### Static Inventory

The simplest way to specify an inventory for Ansible is a flat list of hostnames, one per line:

```ini
webserver1
192.168.0.2
host1.samples.com
```

---
### Host groups

+ Hosts can be grouped under a host group name in brackets  
+ Hosts can be listed under multiple host groups
+ Ungrouped hosts of course can also be listed, before the host group definitions
+ Grouping allows Ansible to easily manage hosts or groups together
+ There are two groups always present: `all` and `ungrouped`

```ini
192.168.0.2

[hostgroup1]
host1
host2

[webservers]
host1
server1.sample.com
server2.sample.com
```

> [!NOTE]
> There are two predefined hostgroups always present implicitly:  
> `all` refers to a flat list of all hosts listed anywhere in the Inventory  
> `ungrouped` refers to all hosts that are not listed under any hostgroups

---
### Nested groups

Using the `:children` suffix host groups can be nested under parent hostgroups.

```ini
[appservers]
appserver1 ansible_host=host1
appserver2 ansible_host=host2

[dbservers]
dbserver1 ansible_host=host2
dbserver2 ansible_host=host3

[myhosts:children]
appservers
dbservers
```

---
### Host ranges and patterns

Using the special range syntax `[begin:end]` many hosts can be specified in a single entry.

```ini
server_[01:12]
[a:d].sample.com
192.168.0.[2:254]
```

Host patterns select hosts from the inventory on the command line (always quote them, `!` and `&` are special for the shell):

```
myhosts:!host1        # exclusion
ungrouped:myhosts     # union
ungrouped:&myhosts    # intersection
myhosts:!{{ not_this }}  # runtime variable
```

```bash
ansible 'myhosts:!host1' --list-hosts
ansible -e not_this=host3 'myhosts:!{{ not_this }}' -m ping
```

---
### Testing Inventories

From the previous session we know how to test inventories with ad-hoc `ansible` command and the option `--list-hosts`.

Save the nested groups example above as `nested_inventory`, then try:

```bash
ansible -i nested_inventory appservers --list-hosts
ansible -i nested_inventory dbservers --list-hosts
ansible -i nested_inventory myhosts --list-hosts
ansible -i nested_inventory ungrouped --list-hosts
ansible-inventory -i nested_inventory --graph
```

How many hosts does `myhosts` contain, and how many real machines are behind them?
(Hint: Ansible counts inventory names, `appserver2` and `dbserver1` both connect to `host2`.)

---
### Overriding default Inventory

Inventory can be defined in a few ways for ansible, listed here in ascending precedence.

1. `/etc/ansible/hosts` (built-in default)
1. `inventory =` in the `ansible.cfg` configuration file
1. `ANSIBLE_INVENTORY` environment variable
1. `--inventory <inventory-path>` or `-i <inventory-path>`

---
### Inventory variables

Host specific variables for playbooks can be defined directly in the Inventory file next to the host names.

```ini
webserver web_port=8081
host1 ansible_host=192.168.0.2
dbserver default_db=cities
```

More on this topic and best practice for ansible variables will be discussed later.

---
### YAML Inventory

The same inventory can be written in YAML as well. [host_inventory.yml](host_inventory.yml) is our
[host_inventory](host_inventory) in YAML format:

```yaml
---
myhosts:
  hosts:
    host1:
      web_port: 8081
    host2:
      web_port: 8082
    host3:
      web_port: 8083
```

+ The top level keys are the groups (the group `all` is implicit, you may also write `all:` and put the groups under
  its `children:`)
+ `hosts:` lists the hosts of a group, every host name ends with a colon, even without variables
+ `vars:` holds the group variables (the INI `[myhosts:vars]` section)
+ `children:` holds the nested groups (the INI `[myhosts:children]` section)

Both formats describe the same inventory:

```bash
ansible-inventory --graph
ansible-inventory -i host_inventory.yml --graph
ansible-inventory --list -y        # shows the INI inventory in YAML: a quick way to convert
```

#### Why YAML: variable types

In YAML a value has a real type: `true` is a boolean, `8080` a number, `[anna, bela]` a list. In the INI format
`true` and `false` stay **strings**. [types.ini](types.ini) and [types.yml](types.yml) define the same variables:

```ini
[myhosts]
host1 http_port=8080 enabled=true users="['anna', 'bela']"
host2
host3

[myhosts:vars]
debug=false
```

```yaml
myhosts:
  hosts:
    host1:
      http_port: 8080
      enabled: true
      users: [anna, bela]
      vhosts:                 # a list of dictionaries: not possible in INI
        - name: shop
          port: 443
        - name: blog
          port: 8443
    host2:
    host3:
  vars:
    debug: false
```

Compare what Ansible makes of them:

```bash
ansible-inventory -i types.ini --host host1
ansible-inventory -i types.yml --host host1
```

| Variable | INI | YAML |
|----------|-----|------|
| `http_port` | `8080` (number) | `8080` (number) |
| `enabled` | `"true"` (**string**) | `true` (boolean) |
| `debug` | `"false"` (**string**) | `false` (boolean) |
| `users` | list, but only in Python syntax inside quotes | list |
| `vhosts` | (cannot be written) | list of dictionaries |

The trap: the string `"false"` is not empty, so it counts as **true** in a condition:

```bash
ansible -i types.ini host1 -m ansible.builtin.debug -a "msg='{{ debug | type_debug }}: {{ debug | ternary(\"ON\", \"off\") }}'"
ansible -i types.yml host1 -m ansible.builtin.debug -a "msg='{{ debug | type_debug }}: {{ debug | ternary(\"ON\", \"off\") }}'"
```

```
host1 | SUCCESS =>
    msg: 'str: ON'
host1 | SUCCESS =>
    msg: 'bool: off'
```

With the INI inventory debugging is switched **on**, although the inventory says `debug=false`. The same happens
later with `when: debug` ([Section 12](../12_ControlFlow/README.md)) and with `{% if debug %}` in a template
([Section 13](../13_Templates/README.md)). In INI write `True`/`False` (Python spelling), or convert with the `bool`
filter: `{{ debug | bool }}`.

| | INI | YAML |
|---|---|---|
| Short and quick to write | ✔ | |
| Booleans, lists, dictionaries as variables | | ✔ |
| Same syntax as Playbooks, `group_vars`, `host_vars` | | ✔ |
| Nested groups visible by indentation | | ✔ |
| Host ranges `host[1:3]` | ✔ | ✔ |
| Typical mistakes | `true` is a string | indentation, missing colon after a host name |

> [!TIP]
> Best practice is to keep the variables in `group_vars/` and `host_vars/` YAML files (see
> [Section 8](../08_Variables/README.md)). Then the inventory only lists hosts and groups, and the two formats are
> equally good. If you put variables into the inventory itself, especially booleans and lists, use YAML.

---
### Multiple Inventories

It is possible to specify more than one inventory with the -i option for ad-hoc ansible commands and ansible playbook executions.

```
ansible all -i inventory1 -i inventory2 -m setup
```

It is also possible to specify an inventory directory in which case Ansible will read all inventory files from that directory

```
ls -l inventory_dir/
-rw-r--r--. 1 devops devops 56 Aug  8  2025 inventory1
-rw-r--r--. 1 devops devops 51 Aug  8  2025 inventory2

ansible all -i inventory_dir -m setup
```

---
### Dynamic Inventory

Dynamic inventories (scripts or plugins that query a cloud, a CMDB, etc.) are discussed in the Automation Platform training.

---
### Bonus (after the Playbooks section)

`inventory-hostname.yml` in this directory sets the system hostname of every Managed Host to its inventory name,
using `inventory_hostname`. Come back to it once you know Playbooks:

```bash
ansible-playbook inventory-hostname.yml
```
