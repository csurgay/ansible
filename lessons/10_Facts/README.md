# Section 10. Facts

### In this section the following subjects will be covered:

1. Ansible Facts
1. Filtering Facts
1. Facts in Playbooks
1. Custom Facts (`facts.d`)
1. Facts set at runtime (`set_fact`)

---
### Ansible Facts

**Facts** are information about the Managed Hosts — OS, network, disks, memory, Python... — collected by the
`setup` module. A Play gathers them automatically at its start (`gather_facts: true`, the default), and they are
available in the `ansible_facts` dictionary.

```bash
ansible host1 -m setup
ansible host1 --become -m setup     # some facts (e.g. hardware details) need root
```

The output is long (several hundred lines). An excerpt from a lab host:

```
host1 | SUCCESS => {
    "ansible_facts": {
        "ansible_all_ipv4_addresses": [
            "10.89.0.14"
        ],
        "ansible_architecture": "x86_64",
        "ansible_default_ipv4": {
            "address": "10.89.0.14",
            "gateway": "10.89.0.1",
            "interface": "eth0",
            "macaddress": "10:10:10:10:10:11",
            ...
        },
        "ansible_distribution": "Fedora",
        "ansible_distribution_major_version": "42",
        "ansible_dns": {
            "nameservers": [
                "10.89.0.1"
            ],
            "search": [
                "dns.podman"
            ]
        },
        "ansible_fqdn": "host1",
        "ansible_hostname": "host1",
        "ansible_interfaces": [
            "lo",
            "eth0"
        ],
        "ansible_local": {},
        "ansible_memtotal_mb": 3907,
        "ansible_os_family": "RedHat",
        "ansible_pkg_mgr": "dnf5",
        "ansible_processor_vcpus": 2,
        "ansible_python_version": "3.13.7",
        "ansible_selinux": {
            "status": "disabled"
        },
        "ansible_service_mgr": "systemd",
        "ansible_virtualization_type": "oci",
        ...
    },
    "changed": false
}
```

Note `ansible_virtualization_type: oci`: Ansible knows it manages a container.

---
### Filtering Facts

```bash
ansible host1 -m setup -a "filter=ansible_distribution*"
ansible host1 -m setup -a "filter=ansible_default_ipv4"
ansible all -m setup -a 'gather_subset=!all,network' | less
```

---
### Facts in Playbooks

In the output of `setup` the facts are prefixed with `ansible_`. Inside `ansible_facts` the prefix is dropped:
`ansible_distribution` becomes `ansible_facts['distribution']`. Prefer the `ansible_facts[...]` form; the
top-level `ansible_*` variables are only a convenience copy.

#### facts.yml
```yaml
---
- name: How to gather ansible facts from hosts
  hosts: host1
  gather_facts: true

  tasks:

    - name: Print a few facts
      ansible.builtin.debug:
        msg:
          - "Hostname: {{ ansible_facts['hostname'] }}"
          - "OS: {{ ansible_facts['distribution'] }} {{ ansible_facts['distribution_version'] }}"
          - "OS family: {{ ansible_facts['os_family'] }}"
          - "IPv4: {{ ansible_facts['default_ipv4']['address'] }}"
          - "Memory: {{ ansible_facts['memtotal_mb'] }} MB"
          - "Python: {{ ansible_facts['python_version'] }}"

    - name: Print all facts (long!)
      ansible.builtin.debug:
        var: ansible_facts
```

```bash
ansible-playbook facts.yml
```

> [!NOTE]
> `debug` has two forms: `var: ansible_facts` takes a variable **name**, `msg: "{{ ... }}"` takes a templated
> string. `var: "{{ ansible_facts }}"` is a common mistake.

Facts of **other** hosts are available through `hostvars`, once they have been gathered in the same run:
`hostvars['host2']['ansible_facts']['default_ipv4']['address']`.

If a Play does not need facts, `gather_facts: false` makes it start faster.

---
### Custom Facts

You can add your own facts to a Managed Host: every `*.fact` file in `/etc/ansible/facts.d/` on the Managed Host is
read by `setup` and appears under `ansible_facts['ansible_local']['<file name>']`. A fact file is either

- **INI** or **JSON** text (static facts), or
- an **executable** script that prints JSON (dynamic facts).

Typical uses: the environment (prod/test) of a server, the application installed on it, its owner team.

#### custom_facts.yml
```yaml
---
- name: Deploy and use custom (local) facts
  hosts: myhosts
  become: true
  gather_facts: false

  tasks:

    - name: Create the facts.d directory
      ansible.builtin.file:
        path: /etc/ansible/facts.d
        state: directory
        mode: '0755'

    - name: Deploy a static custom fact file (INI format)
      ansible.builtin.copy:
        dest: /etc/ansible/facts.d/training.fact
        content: |
          [course]
          name=Ansible Bootcamp
          trainer=devops

          [host]
          environment={{ 'production' if inventory_hostname == 'host1' else 'test' }}
        mode: '0644'

    - name: Re-gather facts, so that the new custom facts are read
      ansible.builtin.setup:
        filter: ansible_local

    - name: Print the custom facts
      ansible.builtin.debug:
        var: ansible_facts['ansible_local']['training']

    - name: Use a custom fact in a condition
      ansible.builtin.debug:
        msg: "{{ inventory_hostname }} is a production server, be careful!"
      when: ansible_facts['ansible_local']['training']['host']['environment'] == 'production'
```

```bash
ansible-playbook custom_facts.yml
ansible host2 -m setup -a "filter=ansible_local"
```

---
### Facts set at runtime

`ansible.builtin.set_fact` creates (or overwrites) a variable for the current host during the run. It behaves
like a fact of that host — other hosts can read it via `hostvars` — but it exists only until the end of the
`ansible-playbook` run (unless fact caching is configured and `cacheable: true` is used).

```yaml
- name: Remember the web root for later tasks
  ansible.builtin.set_fact:
    weblocation: /usr/share/nginx/html/
```

See [08_Variables/pass_variable.yml](../08_Variables/pass_variable.yml) for an example.
