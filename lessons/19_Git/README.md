# Section 19. Git as the source of configuration data

### In this section the following subjects will be covered:

1. Clone a Git repository with the `git` module
1. Load variables from a file at runtime with `include_vars`
1. Share data between Plays through `hostvars`
1. Select one entry of a list with `selectattr` + `first`
1. Fail early with a clear message (`fail`)

See the [Git cheat-sheet](../00_SupportDocs/git.md) for Git itself.

---
## The scenario

The company CMDB is a Git repository, [csurgay/cmdb](https://github.com/csurgay/cmdb). Its `vars.yml` says which
webserver must run on which host:

```yaml
---
data:
  - hostname: host1
    webserver: nginx
  - hostname: host2
    webserver: lighttpd
  - hostname: host3
    webserver: nginx
```

When someone changes the CMDB (a commit), running the Playbook brings the servers in line with it: this is the
basic idea of **GitOps**. In real life a CI/CD pipeline would run the Playbook on every commit.

---
## Two Plays

1. The first Play runs **once**, on the Control Node: it clones the repo to `/tmp/cmdb` and loads `vars.yml`
   with `include_vars`. `name: cmdb` puts all its variables under one dictionary, `cmdb`, so they can't collide
   with other variables: the list is `cmdb.data`.
2. The second Play runs on the `webservers`. Variables of the first Play belong to the host `controlnode` (an inventory alias of `localhost`), so they are read
   through `hostvars['controlnode']['cmdb']['data']`. The entry of the current host is selected with a Jinja2 filter chain:

```yaml
cmdb_entry: "{{ hostvars['controlnode']['cmdb']['data']
                | selectattr('hostname', 'equalto', inventory_hostname)
                | first | default({}) }}"
```

`selectattr` keeps the list elements whose `hostname` equals the current host, `first` takes the first of them,
`default({})` gives an empty dictionary if there is none — and the next task stops that host with a clear message.

#### cmdb.yml
```yaml
---
# The CMDB (a Git repo) says which webserver runs on which host:
#   https://github.com/csurgay/cmdb/blob/main/vars.yml
#   data:
#     - hostname: host1
#       webserver: nginx
#     - ...

- name: Fetch the CMDB configuration on the Control Node
  hosts: controlnode
  become: false
  gather_facts: false
  vars:
    cmdb_repo: https://github.com/csurgay/cmdb.git
    cmdb_dest: /tmp/cmdb

  tasks:
    - name: Clone (or update) the CMDB repository
      ansible.builtin.git:
        repo: "{{ cmdb_repo }}"
        dest: "{{ cmdb_dest }}"
        version: main
        force: true

    - name: Load variables from the cloned vars.yml under the name cmdb
      ansible.builtin.include_vars:
        file: "{{ cmdb_dest }}/vars.yml"
        name: cmdb

    - name: Debug CMDB data
      ansible.builtin.debug:
        var: cmdb.data

- name: Install the webserver the CMDB defines for each host
  hosts: webservers
  become: true
  gather_facts: false
  vars:
    all_webservers: [httpd, nginx, lighttpd]

  tasks:
    - name: Find this host's entry in the CMDB (loaded on the Control Node)
      ansible.builtin.set_fact:
        cmdb_entry: "{{ hostvars['controlnode']['cmdb']['data']
                        | selectattr('hostname', 'equalto', inventory_hostname)
                        | first | default({}) }}"

    - name: Stop if the CMDB has no entry for this host
      ansible.builtin.fail:
        msg: "No CMDB entry for {{ inventory_hostname }}"
      when: cmdb_entry.webserver is not defined

    - name: Stop the other webservers, they would block port 80
      ansible.builtin.systemd:
        name: "{{ item }}"
        state: stopped
      loop: "{{ all_webservers | difference([cmdb_entry.webserver]) }}"
      failed_when: false

    - name: Install the webserver package
      ansible.builtin.dnf:
        name: "{{ cmdb_entry.webserver }}"
        state: present

    - name: Ensure the webserver is running and enabled
      ansible.builtin.systemd:
        name: "{{ cmdb_entry.webserver }}"
        state: started
        enabled: true

    - name: Open HTTP in the firewall
      ansible.posix.firewalld:
        service: http
        permanent: true
        immediate: true
        state: enabled

    - name: Test the webserver from the Control Node
      ansible.builtin.uri:
        url: "http://{{ inventory_hostname }}"
        status_code: [200, 403]   # 403: default test page of some servers without index.html
      register: result_webtest
      delegate_to: controlnode
      become: false

    - name: Show which server answered
      ansible.builtin.debug:
        msg: "{{ inventory_hostname }}: CMDB says {{ cmdb_entry.webserver }}, Server header says {{ result_webtest.server | default('n/a') }}"
```

---
## Running the Playbook

```bash
ansible-playbook cmdb.yml
```

The Control Node needs access to github.com. `ansible.cfg` points at the inventory file `inv`.

**Try this:** fork the CMDB repo, change `cmdb_repo` to your fork, change a webserver there, commit, push, and run
the Playbook again. Then add a host to the inventory that is missing from the CMDB.

> [!NOTE]
> `cmdb_okos.yml` and `service.yml` are an earlier version of the same exercise: they loop over **all** CMDB
> entries on every host and skip the ones that don't match, which is much slower and noisier than selecting
> the one matching entry.
