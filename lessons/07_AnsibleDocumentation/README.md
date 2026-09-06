# Section 7. Ansible Documentation

### In this section the following subjects will be covered:

1. Search for Modules
1. Module Usage Template
1. Official Ansible Documentation

---
### Search for Modules

`ansible-doc` is a built-in cli tool for quick reference on Ansible modules and module usage.

Use `-l` or `--list` for a complete list of installed modules to find something you need. 

`ansible-doc -l | grep firewall`

```
devops@ansible:~$ ansible-doc -l | grep firewalld
ansible.posix.firewalld
ansible.posix.firewalld_info
```

---
### Module Usage Template

Use the `-s` or `--snippet` option for a module template with complete list of arguments with explanations.

`ansible-doc -s firewalld`  

```
devops@ansible:~$ ansible-doc -s firewalld
- name: Manage arbitrary ports/services with firewalld
  firewalld:
      forward:               # The forward setting you would like to enable/disable to/from zones
                             # within firewalld. This option only is
                             # supported by firewalld v0.9.0 or later.
      icmp_block:            # The ICMP block you would like to add/remove to/from a zone in firewall>
      icmp_block_inversion:   # Enable/Disable inversion of ICMP blocks for a zone in firewalld.
      immediate:             # Whether to apply this change to the runtime firewalld configuration.
                             # Defaults to `true' if `permanent=false'.
      interface:             # The interface you would like to add/remove to/from a zone in firewalld.
      masquerade:            # The masquerade setting you would like to enable/disable to/from zones
                             # within firewalld.
      offline:               # Ignores `immediate' if `permanent=true' and firewalld is not running.
      permanent:             # Whether to apply this change to the permanent firewalld configuration.
                             # As of Ansible 2.3, permanent operations
                             # can operate on firewalld configs when it
                             # is not running (requires firewalld >=
                             # 0.3.9). Note that if this is `false',
                             # `immediate=true' by default.
      port:                  # Name of a port or port range to add/remove to/from firewalld. Must be >
                             # the form PORT/PROTOCOL or
                             # PORT-PORT/PROTOCOL for port ranges.
      port_forward:          # Port and protocol to forward using firewalld.
      protocol:              # Name of a protocol to add/remove to/from firewalld.
      rich_rule:             # Rich rule to add/remove to/from firewalld. See Syntax for firewalld ri>
                             # language rules
                             # <https://firewalld.org/documentation/man-pages/firewalld.richlanguage.>
      service:               # Name of a service to add/remove to/from firewalld. The service must be
                             # listed in output of `firewall-cmd
                             # --get-services'.
      source:                # The source/network you would like to add/remove to/from firewalld.
      state:                 # (required) Enable or disable a setting. For ports: Should this port
                             # accept (`enabled') or reject (`disabled')
                             # connections. The states `present' and
                             # `absent' can only be used in zone level
                             # operations (i.e. when no other parameters
                             # but zone and state are set).
      target:                # firewalld Zone target. If `state=absent', this will reset the target to
                             # default.
      timeout:               # The amount of time in seconds the rule should be in effect for when
                             # non-permanent.
      zone:                  # The firewalld zone to add/remove to/from. Note that the default zone c>
                             # be configured per system but `public' is
                             # default from upstream. Available choices
                             # can be extended based on per-system
                             # configs, listed here are "out of the box"
                             # defaults. Possible values include
                             # `block', `dmz', `drop', `external',
                             # `home', `internal', `public', `trusted',
                             # `work'.
```

---
### Official Ansible Documentation

Follow this link for a comprehensive documentation on Ansible:

https://docs.ansible.com/ansible/latest/collections/index_module.html

