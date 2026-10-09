# Section 21: Network Automation

#### In this section the following subjects will be covered:

1. How network automation differs from server automation
1. Connection plugins and `ansible_network_os`
1. Inventory for network devices, `become` with `enable`
1. Examples: facts, show commands, configuration backup, CLI configuration, resource modules
1. Check mode and diff on network devices

> [!IMPORTANT]
> The bootcamp lab has **no network devices**. Run these examples against a lab router or switch (e.g. an IOSv /
> Catalyst 8000v image in Cisco Modeling Labs, GNS3 or EVE-NG), a free
> [Cisco DevNet sandbox](https://developer.cisco.com/site/sandbox/) (check the page for the current address and
> credentials), or follow them as an instructor demo. All Playbooks pass `ansible-playbook --syntax-check`.
> The examples use Cisco IOS / IOS XE; other vendors work the same way with their own collection.

---
## How network automation is different

On a Linux host Ansible copies a Python module to the host and runs it there. A router or switch cannot run Python
modules: the module **runs on the Control Node**, logs in to the device and sends it CLI commands (or API calls),
then parses the answer. Consequences:

- `gather_facts: false` on the Play: the Linux `setup` module would fail; use the vendor's `*_facts` module.
- The connection is **persistent**: Ansible keeps one SSH session per device open for the whole Play instead of
  logging in for every task (timeouts are set in the `[persistent_connection]` section of `ansible.cfg`).
- The modules are vendor and platform specific: `cisco.ios`, `cisco.nxos`, `arista.eos`, `junipernetworks.junos`...
  Generic ones are in `ansible.netcommon` (`cli_command`, `cli_config`, `net_ping`...).

| `ansible_connection` | Protocol | Typical use |
|----------------------|----------|-------------|
| `ansible.netcommon.network_cli` | SSH to the CLI | Most switches and routers (IOS, NX-OS, EOS, Junos...) |
| `ansible.netcommon.netconf` | NETCONF (XML over SSH, port 830) | Junos, IOS XR, IOS XE |
| `ansible.netcommon.httpapi` | HTTP(S) REST API | NX-API, Arista eAPI, firewalls (FortiOS, PAN-OS) |
| `local` | none | **No longer supported** by network modules, you only see it in old Playbooks |

`ansible_network_os` tells the connection plugin which platform it talks to (prompt, error patterns, how to enter
config mode): `cisco.ios.ios`, `cisco.nxos.nxos`, `arista.eos.eos`, `junipernetworks.junos.junos`...

---
## Preparing the Control Node

```bash
# the collections (all of them are part of the full "ansible" package too)
ansible-galaxy collection install cisco.ios ansible.netcommon ansible.utils

# the SSH library used by network_cli (paramiko is the fallback)
pip install ansible-pylibssh            # or: sudo dnf install python3-paramiko
```

---
## Inventory for network devices

#### host_inventory
```ini
[routers]
rtr1 ansible_host=192.168.56.60

# a Layer 2 switch for vlans.yml (a Catalyst or an IOSvL2 image in CML)
[switches]
sw1 ansible_host=192.168.56.61

[ios:children]
routers
switches

[ios:vars]
ansible_user=admin
ansible_connection=ansible.netcommon.network_cli
ansible_network_os=cisco.ios.ios
# enter privileged EXEC mode ("enable") for config commands
ansible_become=true
ansible_become_method=enable
```

- `become` on a network device does not mean `sudo`: `become_method: enable` types `enable` and the enable password
  (`ansible_become_password`, if one is set).
- The password is not in the inventory: [ansible.cfg](ansible.cfg) has `ask_pass = true`. For unattended runs put
  `ansible_password` (and `ansible_become_password`) into a Vault file, e.g. `group_vars/ios/vault.yml`
  ([Section 11](../11_Vault/README.md)). SSH keys work too if the device has them configured.
- `host_key_checking = false` in `ansible.cfg` is for lab devices and sandboxes only.

---
## Example 1: facts

#### facts.yml
```yaml
---
- name: Gather facts from network devices
  hosts: routers
  gather_facts: false             # the Linux "setup" module cannot run on a router

  tasks:
    - name: Gather IOS facts and the VLAN / interface configuration
      cisco.ios.ios_facts:
        gather_subset: min
        gather_network_resources:
          - interfaces
          - vlans

    - name: Show the device
      ansible.builtin.debug:
        msg: >-
          {{ ansible_net_hostname }} is a {{ ansible_net_model | default('?') }}
          running IOS {{ ansible_net_version }} ({{ ansible_net_iostype }})

    - name: Show the interfaces as structured data
      ansible.builtin.debug:
        var: ansible_network_resources.interfaces
```

The legacy facts are `ansible_net_*` variables; the configuration of each **network resource** (interfaces, VLANs,
ACLs, OSPF...) is returned as structured YAML under `ansible_network_resources`. You can write the same structure
back with the resource modules (Example 5).

---
## Example 2: show commands

#### show.yml
```yaml
    - name: Run show commands, wait until the device is ready
      cisco.ios.ios_command:
        commands:
          - show version
          - show ip interface brief
        wait_for:
          - result[0] contains IOS
      register: out

    - name: Print the interface table
      ansible.builtin.debug:
        var: out.stdout_lines[1]
```

`ios_command` only runs **show** (exec) commands, never configuration, and it is never `changed`. `stdout` is a list:
one element per command. `wait_for` retries until the condition is true (handy after a reload).

Ad-Hoc works too:
```bash
ansible routers -m cisco.ios.ios_command -a "commands='show clock'"
```

---
## Example 3: configuration backup

#### backup.yml
```yaml
    - name: Save the running-config to the Control Node
      cisco.ios.ios_config:
        backup: true
        backup_options:
          dir_path: ./backups
          filename: "{{ inventory_hostname }}.cfg"
```

Run it before every change, or nightly from cron / AWX. Commit the `backups` directory to Git and you have a
versioned history of every device configuration ([Section 19](../19_Git/README.md)).

---
## Example 4: configuration with CLI lines

#### config.yml
```yaml
    - name: Global configuration lines
      cisco.ios.ios_config:
        lines:
          - "ntp server {{ ntp_server }}"
          - service timestamps log datetime msec
        save_when: modified

    - name: Interface configuration (lines under a parent)
      cisco.ios.ios_config:
        parents: "interface {{ uplink }}"
        lines:
          - description Uplink - managed by Ansible
        save_when: modified

    - name: Login banner
      cisco.ios.ios_banner:
        banner: motd
        text: |
          Authorized access only.
          This device is managed by Ansible - manual changes will be overwritten.
        state: present
```

How `ios_config` stays idempotent: it reads the running-config and sends **only the lines that are missing** under
the given `parents`. Write the lines exactly as they appear in `show running-config` (no abbreviations like
`int gi1`), otherwise they never match and the task is `changed` every time.
`save_when: modified` copies the running-config to the startup-config (`write memory`) only if something changed.

**Check mode and diff** work on network devices too, always use them before a change:
```bash
ansible-playbook config.yml --check --diff     # shows the lines it would send, changes nothing
ansible-playbook config.yml --diff
```

---
## Example 5: resource modules

`ios_config` pushes **text lines**. Resource modules (`ios_vlans`, `ios_interfaces`, `ios_l2_interfaces`,
`ios_l3_interfaces`, `ios_acls`, `ios_static_routes`, `ios_ospfv2`, `ios_bgp_global`, `ios_ntp_global`,
`ios_user`...) take **structured data** and work out the commands themselves.

#### vlans.yml
```yaml
    - name: Make sure the VLANs exist (other VLANs are left alone)
      cisco.ios.ios_vlans:
        config:
          - vlan_id: 10
            name: USERS
          - vlan_id: 20
            name: SERVERS
        state: merged

    - name: Put two ports into the VLANs as access ports
      cisco.ios.ios_l2_interfaces:
        config:
          - name: GigabitEthernet0/1
            mode: access
            access:
              vlan: 10
          - name: GigabitEthernet0/2
            mode: access
            access:
              vlan: 20
        state: merged

    - name: Read the VLANs back as structured data
      cisco.ios.ios_vlans:
        state: gathered
      register: vlans
```

The `state` decides what happens with the configuration that is **not** in your list:

| `state` | Effect |
|---------|--------|
| `merged` | Add / update what is listed, leave everything else alone (the safe default) |
| `replaced` | The listed items get exactly this config (other attributes of *these* items are removed) |
| `overridden` | The device gets exactly this list: everything not listed is **removed** (careful!) |
| `deleted` | Remove the listed items (or all of them with an empty `config`) |
| `gathered` | Read the current config as structured data (like the facts) |
| `rendered` | Return the CLI commands for `config` without changing the device |
| `parsed` | Turn a saved config text (`running_config:`) into structured data |

With `gathered` you can export a device's VLANs, keep them as YAML in Git, and push them to other switches with
`merged` or `overridden`: this is the "source of truth" approach of network automation.

---
## Linux vs network devices

| | Linux host | Network device |
|---|---|---|
| Module runs on | the Managed Host (Python) | the Control Node |
| `gather_facts` | `setup` (default) | `false` + `<vendor>_facts` |
| Connection | `ssh` | `network_cli`, `netconf`, `httpapi` |
| Platform | detected from the facts | `ansible_network_os` must be set |
| `become` | `sudo` | `enable` |
| Save the change | not needed | `save_when: modified` (running- to startup-config) |

---
## Exercise

1. Run `facts.yml` and find the serial number of the device in `ansible_net_serialnum`.
1. Run `backup.yml`, then `config.yml --check --diff`, then `config.yml`. Run it a second time: is it `changed`?
1. Change `description Uplink - managed by Ansible` to `desc Uplink`. Why is the task `changed` on every run now?
1. Add VLAN 30 `PRINTERS` to `vlans.yml`. What would happen to VLANs 10 and 20 if you changed `state: merged` to `overridden` and listed only VLAN 30?

---
#### Further reading
- [Network Getting Started](https://docs.ansible.com/ansible/latest/network/getting_started/index.html)
- [Network resource modules](https://docs.ansible.com/ansible/latest/network/user_guide/network_resource_modules.html)
- [cisco.ios collection](https://docs.ansible.com/ansible/latest/collections/cisco/ios/index.html)
