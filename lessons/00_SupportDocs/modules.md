# Ansible modules

## Some frequently used Modules

| Category | Module | Description |
|----------|--------|-------------|
| Files modules | ansible.builtin.**copy** | Copy a local file to Managed Hosts |
| | ansible.builtin.**fetch** | Fetch a remote file to the Control Node |
| | ansible.builtin.**file** | Set permissions and other properties of files |
| | ansible.builtin.**lineinfile** | Ensure a particular line is or is not in a file |
| | ansible.posix.**synchronize** | Synchronize content using rsync |
| Package modules | ansible.builtin.**package** | Autodetected package manager |
| | ansible.builtin.**yum** | YUM package manager |
| | ansible.builtin.**apt** | APT package manager |
| | ansible.builtin.**dnf** | DNF package manager |
| | ansible.builtin.**gem** | Manage Ruby gems |
| | ansible.builtin.**pip** | Manage Python packages from PyPI |
| System modules | ansible.posix.**firewalld** | Ports and services management |
| | ansible.builtin.**reboot** | Reboot a machine |
| | ansible.builtin.**service** | Manage services on generic systems |
| | ansible.builtin.**systemd** | Manage services on systemd specific systems |
| | ansible.builtin.**user** | Add, remove, and manage user accounts |
| Command modules | ansible.builtin.**command** | Executes a single command |
| | ansible.builtin.**shell** | Runs the command on a new Shell (redirection, pipes...) |
| | ansible.builtin.**raw** | Executes a single command without python involved (for installing python) |
| Net Tools modules| ansible.builtin.**get_url** | Download files over HTTP, HTTPS, or FTP |
| | community.general.**nmcli** | Manage networking |
| | ansible.builtin.**uri** | Interact with web services |

---
## Usage of Modules

---
### File Module

#### Create directory

```yaml
- name: Create a log directory
  file:
    path: /var/log/myapp
    state: directory
    mode: '0755'
```

This makes a directory at /var/log/myapp with standard permissions. Run it again? No problem—it won’t redo what’s already there.

#### Delete file

```yaml
- name: Delete an old log
  file:
    path: /var/log/old.log
    state: absent
```

---
### Package (dnf) Module

#### Installing Nginx

```yaml
- name: Install Nginx
  dnf:
    name: nginx
    state: present
```

This checks if Nginx is installed and adds it if not. 

#### Update all

```yaml
- name: Update all packages
  dnf:
    name: "*"
    state: latest
```

---
### Service Module (Systemd Module)

| Feature	| Service Module | Systemd Module |
|---------|----------------|----------------|
| Platform support | Universal across Unix-like systems	| Specific to systemd-enabled systems |
| Service manager detection	| Automatic detection of underlying service manager	| Direct systemd integration only | 
| Advanced features	| Basic service operations (start, stop, restart, enable)	| Advanced systemd features (masking, daemon-reload, user services) | 
| Dependency management	| Limited dependency handling	| Comprehensive systemd dependency management | 
| Unit file management | No direct unit file manipulation	| Direct unit file creation and modification | 
| Socket management	| Not supported	| Full socket unit support | 
| Performance	| Lightweight, minimal overhead	| Feature-rich with additional overhead | 
| Portability	| High portability across different init systems	| Limited to systemd environments | 
| State management	| Basic state control	| Advanced state management with service properties | 

#### Start and enable Nginx

```yaml
- name: Start and enable Nginx
  service:
    name: nginx
    state: started
    enabled: yes
```

#### Restart Nginx

After e.g. config modification.

```yaml
- name: Restart Nginx
  service:
    name: nginx
    state: restarted
```

#### Multiple restarts

```yaml
- name: Restart multiple services
  hosts: appservers
  become: yes

  tasks:

    - name: Restart application services
      ansible.builtin.service:
        name: "{{ item }}"
        state: restarted
      loop:
        - redis
        - postgresql
        - myapp
```

#### Service Status

```yaml
- name: Check Service Status
  hosts: all
  become: yes

  tasks:
    - name: Get service information
      ansible.builtin.service_facts:
    
    - name: Show Nginx Status
      debug:
        msg: "Nginx status: {{ ansible_facts.services['nginx.service'].state }}"
      when: "'nginx.service' in ansible_facts.services"
```

#### Capture Output

```yaml
- name: Capture Output
  ansible.builtin.service:
    name: nginx
    state: started
  register: result_nginx

- name: Display response
  debug:
    var: result_nginx
```

#### Multiple Services State

```yaml
- name: Check Multiple Services State
  hosts: all
  gather_facts: false

  tasks:

    - name: Check services is-active
      shell: systemctl is-active {{ item }}
      register: results_state
      loop:
        - sshd
        - nginx
        - firewalld
      ignore_errors: true

    - name: Display Services State
      debug:
        msg: "{{ item.item }} service status: {{ item.stdout }}"
      loop: "{{ results_state.results }}"
```

---
### User Module

#### Create user

```yaml
- name: Add Sarah with sudo
  user:
    name: sarah
    state: present
    groups: wheel
    shell: /bin/bash
```

#### Remove user

```yaml
- name: Remove Sarah
  user:
    name: sarah
    state: absent
```

---
### Template Module

#### Deploy Nginx config

```yaml
- name: Set up Nginx config
  template:
    src: /path/to/nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  notify: restart nginx
```

This uses a template file (.j2) and restarts Nginx if it changes.

---
## Advanced Module Usage

### Looping Over Tasks

Install multiple packages at once with a loop:

```yaml
- name: Install several packages
  package:
    name: "{{ item }}"
    state: present
  loop:
    - nginx
    - git
    - curl
```

This installs all three in one shot.

### Waiting for Something

```yaml
- name: Wait for port 80 to be open
  wait_for:
    port: 80
    state: started
```

This waits until port 80 is active.

### Checking Conditions

Run a task only if something’s true:

```yaml
- name: Restart if needed
  service:
    name: nginx
    state: restarted
  when: restart_needed
```

This restarts `nginx` only if `restart_needed` is true.

---
## Best Practices for Using Ansible Modules

### Name Your Tasks, Plays, Playbooks

Task name is optional, but it is a good idea to always name your tasks using the name attribute. It will also make reading and debugging your playbooks much more convenient. When you execute a playbook, Ansible displays the name of the task that it is executing, and you can search for these names in long logs.

### Use Variables

Avoid hardcoded values in your playbooks. Rather than doing it, use variables. To give a specific example, rather than hardcoding a username of Dave in the application, you can use a variable such as `{{ developer_user }}`. This makes your playbooks more reusable and flexible.

### Check for existing modules 

Before you consider writing a custom module, always check in Ansible Galaxy to see whether someone has done one similar to what you need.

### Read documentation

Each Ansible module has documentation on how to use all of its options and examples as well. When you open a new module, spend some time reading the documentation. It will prevent you from tons of headaches later. `ansible-doc <module_name>` will give you the documentation of any module on your command line.
