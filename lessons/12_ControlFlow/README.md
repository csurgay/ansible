# Section 12. Control Flow

### In this section the following subjects will be covered:

1. Conditions
1. Loops
1. Handlers
1. Blocks
1. Error handling
1. Delegation
1. Conditional Roles

All examples are runnable Playbooks in this directory (`ansible.cfg` and `host_inventory` included:
`host1`, `host2` are `webservers`, `host3` is in `databases`).

---
## Conditions

Conditions are evaluated by the `when:` keyword. It takes a raw Jinja2 expression, **without** `{{ }}`.
Some useful expressions are:

- `when: variable is defined`
- `when: variable is undefined`
- `when: result is failed`
- `when: result is succeeded`
- `when: result is skipped`
- `when: result is changed`
- `when: ansible_facts['os_family'] == "RedHat"`
- `when: "'webservers' in group_names"`
- `and`, `or`, `not`, and a list of conditions (all of them must be true):

```yaml
when: ansible_facts['os_family'] == "RedHat" and ansible_facts['distribution_major_version'] | int >= 9
```

```yaml
when:
  - ansible_facts['os_family'] == "RedHat"
  - ansible_facts['distribution_major_version'] | int >= 9
```

> [!NOTE]
> `is` is for Jinja2 **tests** (`is defined`, `is failed`, `is changed`...). To compare values use `==`, `!=`, `<`, `>`, `in`.

#### conditions.yml
```yaml
---
- name: Variable as Condition
  hosts: host1
  gather_facts: false
  vars:
    weather: good   # or bad, try: -e weather=bad

  tasks:

    - name: Task based on the weather variable
      ansible.builtin.debug:
        msg: "Yay! We go hiking!"
      when: weather == "good"

    - name: Task based on the weather variable
      ansible.builtin.debug:
        msg: "Staying home to play chess!"
      when: weather == "bad"

- name: Fact as Condition
  hosts: webservers
  gather_facts: true
  become: true

  tasks:

    - name: Install httpd on the Red Hat family (RHEL, Fedora, CentOS, ...)
      ansible.builtin.dnf:
        name: httpd
        state: present
      when: ansible_facts['os_family'] == 'RedHat'

    - name: Install apache2 on Debian and Ubuntu
      ansible.builtin.apt:
        name: apache2
        state: present
      when: ansible_facts['distribution'] == 'Debian' or
            ansible_facts['distribution'] == 'Ubuntu'

- name: Registered result and NOT as Condition
  hosts: host1
  gather_facts: false
  vars:
    mountpoint: /srv/data

  tasks:

    - name: Check mountpoint exists
      ansible.builtin.stat:
        path: "{{ mountpoint }}"
      register: mountpoint_stat

    - name: Create mountpoint
      ansible.builtin.file:
        path: "{{ mountpoint }}"
        state: directory
        mode: "0755"
      when: not mountpoint_stat.stat.exists
```

```bash
ansible-playbook conditions.yml
ansible-playbook conditions.yml -e weather=bad
```

The lab hosts run Fedora: `ansible_facts['distribution']` is `Fedora`, `ansible_facts['os_family']` is `RedHat`.
That is why the httpd task uses `os_family`: a test for `distribution == 'RedHat'` would skip on Fedora.

---
## Loops

`loop:` repeats a task for each item of a list, the current item is `{{ item }}`. You will also meet the older
`with_items:` form in existing playbooks.

#### loops.yml
```yaml
---
- name: Variable list Loops
  hosts: webservers
  become: true
  gather_facts: false

  tasks:

    - name: Create several directories
      ansible.builtin.file:
        path: "/srv/{{ item }}"
        state: directory
        mode: '0755'
      loop:
        - logs
        - backup
        - data

    - name: Install a list of packages (no loop needed, the module takes a list)
      ansible.builtin.dnf:
        name:
          - git
          - tree
          - vim
        state: present

- name: Combining Loops and Conditions
  hosts: webservers:databases
  become: true
  gather_facts: false
  vars:
    apps:
      - name: httpd
        hostgroups: ['webservers']
      - name: mariadb-server
        hostgroups: ['databases']
      - name: git
        hostgroups: ['webservers', 'databases']

  tasks:

    - name: Deploy packages based on hostgroup
      ansible.builtin.dnf:
        name: "{{ item.name }}"
        state: present
      when: item.hostgroups | intersect(group_names) | length > 0
      loop: "{{ apps }}"
      loop_control:
        label: "{{ item.name }}"

- name: Loop through Inventory
  hosts: localhost
  gather_facts: false

  tasks:

    - name: Print every host with its groups
      ansible.builtin.debug:
        msg: "{{ item }} : {{ hostvars[item].group_names }}"
      loop: "{{ groups['all'] }}"
```

```bash
ansible-playbook loops.yml
```

Notes:
- Many modules (`dnf`, `package`, `apt`) accept a list in `name:` — faster than a loop (one transaction).
- `item.hostgroups | intersect(group_names) | length > 0` is true if the host is in **any** of the listed groups.
- `loop_control: label:` shortens what is printed for each iteration.

---
## Handlers

Tasks can `notify` handlers. A handler runs **once**, at the end of the Play, and only if at least one notifying
task reported `changed`. Typical use: restart a service only when its configuration changed.

#### handlers.yml
```yaml
---
- name: Handlers illustration
  hosts: webservers
  become: true
  gather_facts: false
  vars:
    training_header: "Ansible Bootcamp"

  tasks:

    - name: nginx is installed
      ansible.builtin.dnf:
        name: nginx
        state: present

    - name: Write a small nginx config snippet
      ansible.builtin.copy:
        dest: /etc/nginx/default.d/training.conf
        content: |
          # Managed by Ansible
          add_header X-Training "{{ training_header }}";
        mode: '0644'
      notify: Restart nginx

    - name: nginx is running
      ansible.builtin.service:
        name: nginx
        state: started
        enabled: true

  handlers:

    - name: Restart nginx
      ansible.builtin.service:
        name: nginx
        state: restarted
```

```bash
ansible-playbook handlers.yml                                  # 1st run: handler runs
ansible-playbook handlers.yml                                  # 2nd run: nothing changed, no restart
ansible-playbook handlers.yml -e training_header=Hello     # config changes: handler runs
curl -sI http://host1 | grep X-Training
```

If a handler must run earlier than the end of the Play, add a task `- ansible.builtin.meta: flush_handlers`.

---
## Blocks

A number of Tasks can be grouped into a Block, so that `when`, `become`, `tags` etc. apply to all of them.
(Loops can **not** be applied to a block; to loop over a group of tasks use `include_tasks` with `loop`.)

Blocks are also used for error handling: if a task in `block` fails, the `rescue` tasks run (like `try`/`except`),
and the `always` tasks run in any case (like `finally`). `ansible_failed_result` holds the result of the failed task.

#### blocks.yml
```yaml
---
- name: Block of Tasks
  hosts: webservers
  gather_facts: true

  tasks:

    - name: Install and start nginx, only on the Red Hat family
      when: ansible_facts['os_family'] == 'RedHat'
      become: true
      block:

        - name: Install nginx
          ansible.builtin.dnf:
            name: nginx
            state: present

        - name: Start and enable service
          ansible.builtin.service:
            name: nginx
            state: started
            enabled: true

- name: Error handling with Blocks
  hosts: host1
  gather_facts: false

  tasks:

    - name: Catching errors
      block:

        - name: Print a message
          ansible.builtin.debug:
            msg: 'I execute normally'

        - name: Force a failure
          ansible.builtin.command: /bin/false

        - name: Never print this
          ansible.builtin.debug:
            msg: 'I never execute, due to the above failure'

      rescue:

        - name: Print when errors
          ansible.builtin.debug:
            msg: 'I caught an error: {{ ansible_failed_result.rc }}'

      always:

        - name: Always do this
          ansible.builtin.debug:
            msg: "This always executes"
```

```bash
ansible-playbook blocks.yml
```

---
## Error handling

By default a task fails when the module says so (e.g. a command returns a non-zero exit code), and a failed host
stops executing the Play. These keywords change that:

| Keyword | Effect |
|---------|--------|
| `changed_when: <condition>` | Decide yourself when the task counts as `changed` (`false` for read-only commands) |
| `failed_when: <condition>` | Decide yourself when the task counts as `failed` |
| `ignore_errors: true` | The task fails (red), but the Play continues on this host |
| `until:` / `retries:` / `delay:` | Repeat the task until the condition is true |
| `ansible.builtin.fail` | Fail on purpose, with your own message |
| `ansible.builtin.assert` | Fail unless all conditions in `that:` are true |
| `any_errors_fatal: true` (Play) | Stop the whole Play on all hosts if one host fails |

#### errors.yml
```yaml
---
- name: Deciding what is failed and what is changed
  hosts: host1
  gather_facts: false

  tasks:

    - name: A read-only command never changes anything
      ansible.builtin.command: cat /etc/os-release
      register: result_os
      changed_when: false

    - name: grep returns 1 if nothing matches, which is not an error for us
      ansible.builtin.command: grep -c nginx /etc/passwd
      register: result_grep
      changed_when: false
      failed_when: result_grep.rc > 1

    - name: Print whether an nginx user exists
      ansible.builtin.debug:
        msg: "nginx user exists: {{ result_grep.rc == 0 }}"

    - name: Ignore errors (the task is red, but the Play continues)
      ansible.builtin.command: /bin/false
      ignore_errors: true

    - name: Start a background job that creates a flag file after 3 seconds
      ansible.builtin.shell: "sleep 3 && touch /tmp/ready_flag"
      async: 10
      poll: 0
      changed_when: false

    - name: Wait for the flag file, at most 5 x 2 seconds
      ansible.builtin.stat:
        path: /tmp/ready_flag
      register: result_flag
      until: result_flag.stat.exists
      retries: 5
      delay: 2

    - name: Fail the Play on purpose with a clear message
      ansible.builtin.fail:
        msg: "Too few CPUs"
      when: false   # try: when: true
```

```bash
ansible-playbook errors.yml
```

---
## Delegation

Tasks can be delegated for execution to another host than the one currently processed, e.g. to the Control Node
(`localhost`). With `run_once: true` the delegated task runs only once instead of once per host.

```yaml
- name: Download once on the Control Node, distribute to the Managed Hosts
  hosts: webservers
  become: true
  tasks:
    - name: Download a file to the Control Node
      ansible.builtin.get_url:
        url: "https://example.com/files/app-1.0.tar.gz"
        dest: "/tmp/app-1.0.tar.gz"
      delegate_to: localhost
      run_once: true
      become: false

    - name: Copy it to the Managed Hosts
      ansible.builtin.copy:
        src: "/tmp/app-1.0.tar.gz"
        dest: "/opt/"
```

This pattern is useful when the Managed Hosts have no internet access but the Control Node does.
See also [14_LinuxAdminLabs/07-backup](../14_LinuxAdminLabs/07-backup/README.md).

---
## Conditional Roles

Roles (see [15_Roles](../15_Roles/README.md)) can also be applied conditionally:

```yaml
---
- name: Roles Conditions
  hosts: all
  roles:
    - role: nginx
      when: "'webservers' in group_names"
    - role: mariadb
      when: "'databases' in group_names"
```
