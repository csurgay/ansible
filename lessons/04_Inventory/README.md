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

Inventory can be places into the `/etc/ansible/hosts` file, or  
into any file in the directories where we run Ansible.

This latter case is more of the best practice, when the file is referenced along with `ansible` command:  
`ansible-playbook -i ./inventory playbook.yml`

---
### Static Inventory

The most simple way to specify an inventory for ansible is a flat list of hostnames one per lines:

```
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
+ There are two gourps always present `all` and `ungrouped`

```
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

```
[appservers]
appserver1 ansible_host=host1
appserver2 anisble_host=host2

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

```
server_[01:12]
[a:d].sample.com
192.168.0.[2:254]
```

```
myhosts:!host1 # exclusion
ungrouped:myhosts # union
ungrouped:&myhosts # intersection
myhosts:!{{ not_this }} # runtime variable
```

`ansible -e not_this=host3 'myhosts:!{{ not_this }}' -m ping`

---
### Testing Inventories

From the previous session we know how to test inventories with ad-hoc `ansible` command and the option `--list-hosts`.

```
ansible appservers --list-hosts
ansible dnservers --list-hosts
ansible servers --list-hosts
```

---
### Overriding default Inventory

Inventory can be defined in a few ways for ansible, listed here in ascending precedence.

1. `/etc/ansible/inventory`
1. `ansible.cfg` configuration file
1. `--inventory <inventory-path>` or `-i <inventory-path>`

---
### Invetory variables

Host specific variables for playbooks can be defined directly in the Inventory file next to the host names.

```
webserver web_port=8081
host1 ansible_host=192.168.0.2
dbserver default_db=cities
```

More on this topic and best practice for ansible variables will be discussed later.

---
### Dynamic Inventory

This topic is discussed in the Automation Platform training.
