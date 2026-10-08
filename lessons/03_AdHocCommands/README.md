# Section 3. Ansible Ad-Hoc Commands

### In this section the following subjects will be covered:

1. Checking the Inventory (`--list-hosts`)
1. Specify Inventory for ansible (`--inventory <inventory-file>`)
1. Testing Connectivity (`ping`)
1. Running Commands (`command` and `shell`)
1. Elevated privileges (`--become` and `--ask-become-pass`)
1. File Transfer (`copy` and `fetch`)
1. Package Management (`package`, `yum` / `apt`)
1. Managing Services (`service` / `systemd`)
1. User and Group Management (`user` / `group`)
1. File Permissions (`file`)
1. Gathering Facts (`setup`)
1. Rebooting Hosts (`reboot`)
1. Limit and Control Parallel Processes (`--limit` and `--forks`)
1. Final Exercise: Multi-Step Task

> [!IMPORTANT]
> This directory contains no Ansible project files yet, you create them now. Work in `lessons/03_AdHocCommands`
> and create the two files below. Ansible always reads `./ansible.cfg` from the current directory first.

#### inventory
```ini
host1
host2
host3
```

#### ansible.cfg
```ini
[defaults]
inventory = ./inventory
remote_user = devops
interpreter_python = /usr/bin/python3
```

#### ansible command
```bash
ansible all -m <module> -a "<module arguments>"
```

## Ad-Hoc commands

Ansible **Ad-Hoc commands** are simple, one-liner commands that allow you to quickly perform tasks on managed hosts  
**without writing a playbook**. They are useful for quick testing, troubleshooting, or executing tasks across multiple systems.

Ad-Hoc commands are executed with the **`ansible`** command-line tool and generally follow this structure:

```
ansible <host-pattern> <options> -m <module> -a "<module-options>"
```

* **`<host-pattern>`** → Specifies target hosts (from the inventory)
  * `all`
  * `localhost`
  * any hostgroups
  * single hosts or IP addresses
  * set of hosts, wildcards, regular expressions
* **`<options>`** → Options for the ansible command
  * `-i`, `--inventory`: location of inventory file
  * `--list-hosts`: list hosts from inventory
  * `-u`, `--user`: ssh user
  * `-b`, `--become`: become root on managed host
  * `--become-user`: default is root, can be other user
  * `-K`, `--ask-become-pass`: asks for sudo password on managed host
  * `-f`, `--forks`: number of parallel processes
  * `-l`, `--limit`: limit hosts to specified group or pattern
* **`-m <module>`** → Defines the module to use (e.g., `ping`, `shell`, `copy`)
* **`-a "<module-options>"`** → Provides arguments to the module

> [!TIP]
> To avoid using the command `ansible` in the VM instead of the control node container by mistake,  
> it might be good practice to create an alias in the VM shell for `ansible` to print a warning:  
> `alias ansible='echo "This is not the control node!"'`
---

### Checking the Inventory (`--list-hosts`)

```
ansible all --list-hosts
```

Lists all hosts from the inventory configured in `ansible.cfg`.

**Exercise:**

* List hosts from default inventory.

---

### Specify Inventory for ansible (`--inventory <inventory-file>`)

```
printf "localhost\nhost1\n" > inv2
ansible all --list-hosts --inventory inv2
```

Lists all hosts from a specific inventory file.

**Exercise:**

* List hosts from a specific inventory file.

---

### Testing Connectivity (`ping`)

```
ansible all -m ping
```

Checks if hosts are reachable.

**Exercise:**

* Run the ping command on all hosts.
* Run it on a specific group or host.

---

### Running Commands (`command` and `shell`)

* **`command` module** → Runs commands without using a shell.
* **`shell` module** → Runs commands through a shell (`/bin/sh`).

```
ansible all -m command -a "uptime"
ansible all -m shell -a 'echo $HOME'
```

**Exercise:**

* Use `command` to display the system’s uptime.
* Use `shell` to check the current user’s home directory.
* Now run it with double quotes: `ansible all -m shell -a "echo $HOME $HOSTNAME"`. Why does every host print
  `ansible`? (Hint: who expands `$...` inside double quotes, your local shell or the Managed Host?)

> [!WARNING]
> Although Ansible is idempotent and reports changes through colored output, `shell` and `command` modules always report “changed”, because Ansible cannot determine actual effect of arbitrary operations on the system.

---

### Elevate privileges (`--become` and `--ask-become-pass`)

* **Become root at managed host**:

```
ansible all --become -m shell -a whoami
```

This prints `root` for every host: in the lab, user `devops` has **passwordless** `sudo`
(see `/etc/sudoers.d/devops` on the Managed Hosts).

* **Ask to provide `sudo` password**:

```
ansible all --become --ask-become-pass -m shell -a whoami
```

On real servers `sudo` usually asks for the user's password. `-K` (`--ask-become-pass`) makes Ansible prompt
for it once and use it on all managed hosts. In the lab you can type anything (or `devops`), since no
password is required.

> [!NOTE]
> The reason why it's called "become" is that there can be other elevations than `sudo`.  
> See `--become-method`

**Exercise:**

* Try becoming `root` and using `shell` module to `whoami` on host1.
* Try the same but with providing the `sudo` password for the managed host.
* Try `whoami` without `--become`: which user does Ansible log in as, and where is that configured?

---

### File Transfer (`copy` and `fetch`)

* **Copy files to remote hosts** and check results:

```
ansible all -m copy -a "src=/etc/hosts dest=/tmp/hosts_backup"
ansible all -m command -a "cat /tmp/hosts_backup"
```

* **Fetch files from remote hosts** and check results:

```
ansible all -m fetch -a "src=/etc/hosts dest=/tmp/hosts"
tree /tmp/hosts/
cat /tmp/hosts/*/etc/hosts
```

**Exercise:**

* Copy a local script to `/usr/local/bin` on all hosts and check results

```
echo "ls -la" > myscript.sh
ansible all -m copy -a "src=myscript.sh dest=/usr/local/bin mode=0755" --become --ask-become-pass
ansible all -m command -a "cat /usr/local/bin/myscript.sh"
```

* Fetch `/etc/redhat-release` from all hosts into `/tmp/hosts/`:

```
ansible all -m fetch -a "src=/etc/redhat-release dest=/tmp/hosts"
tree /tmp/hosts/
cat /tmp/hosts/*/etc/redhat-release
```

---

> [!WARNING]
> From here onwards let's set privilege escalation in `ansible.cfg` so that no `--become` option is necessary.
> Append this section to your `ansible.cfg`:
> ```ini
> [privilege_escalation]
> become = true
> become_ask_pass = false
> ```
> (`become_ask_pass = true` would prompt for the sudo password at every command, which is only useful
> where sudo really needs a password.)

### Package Management (`package`, `dnf` / `apt`)

```
ansible all -m dnf -a "name=git state=present"
ansible all -m dnf -a "name=nginx state=present"
```

`package` picks the right package manager automatically, `dnf` (Fedora/RHEL) and `apt` (Debian/Ubuntu) are the
specific ones. (`yum` still works on RHEL, but in current Ansible it is just an alias of `dnf`.)

**Exercise:**

* Install `git` on all hosts. (Note, that because of idempotency nothing changes, it is already installed.)

```
ansible all -m dnf -a "name=git state=present"
```

* Install `tmux` on all hosts, then remove it from a specific host.

```
ansible all -m package -a "name=tmux state=present"
ansible host1 -m package -a "name=tmux state=absent"
```

---

### Managing Services (`service` / `systemd`)

```
ansible all -m service -a "name=nginx state=started"
ansible all -m systemd -a "name=nginx enabled=yes state=stopped"
```

**Exercise:**

* Start the `nginx` service on all hosts (installed in the previous section).

```
ansible all -m service -a "name=nginx state=started"
```

* Enable the service to auto-start on boot.

```
ansible all -m systemd -a "name=nginx enabled=yes"
```

---

### User and Group Management (`user` / `group`)

```
ansible host1 -m group -a "name=developers state=present"
ansible host1 -m user -a "name=deploy state=present"
ansible host1 -m user -a "name=deploy groups=developers append=true state=present"
ansible host1 -m command -a "id deploy"
```

> [!CAUTION]
> Without `append=true` the `groups` list **replaces** all secondary groups of the user.

**Exercise:**

* Create a user `ansibleuser` on all hosts.

```
ansible all -m user -a "name=ansibleuser state=present"
```

* Remove user `deploy` and then the `developers` group from host1.

```
ansible host1 -m user -a "name=deploy state=absent remove=true"
ansible host1 -m group -a "name=developers state=absent"
```

* Try to delete the `devops` group from host1. Why does it fail? (Hint: `id devops`)

---

### File Permissions (`file`)

```
ansible all -m file -a "path=/tmp/testdir state=directory mode=0755"
```

**Exercise:**

* Create a directory `/opt/ansible` with `0750` permissions.
* Remove `/tmp/testdir`.

---

### Gathering Facts (`setup`)

```
ansible all -m setup
ansible all -m setup -a "filter=ansible_distribution*"
```

**Exercise:**

* Gather all facts from a host.
* Filter facts to show only OS-related information.

---

### Rebooting Hosts (`reboot`)

```
ansible all -m reboot
```

**Exercise:**

* Reboot all hosts and wait for them to come back.
* Test if they are online with `ping`.

> [!CAUTION]
> Never reboot the Control Node (`localhost`) this way, you would lose your session.
> Containers do not come back after reboot in default behaviour, so they are run by `--restart always`. Check status by `sudo podman ps -a`. Still, to get back with ssh can take some time.  
> If you happen to stop them by accident, restart them by `sudo podman start ansible host1 host2 host3`

---

### Limit and Control Parallel Processes (`--limit` and `--forks`)

* Run against **specific subset (`--limit <host-pattern>`) of hosts**:

```
ansible all -m ping --limit host1
```

* Control **parallelism** with `-f` (forks):

```
ansible all -m ping -f 1
```

**Exercise:**

* Run a command on just 1 host.
* Run `ping` on all hosts with `-f 1`.

---

### Final Exercise: Multi-Step Task

1. Ping all hosts:

```
ansible all -m ping
```

2. Install `nginx`:

```
ansible all -m package -a "name=nginx state=present"
```

3. Copy a custom index.html:

```
printf "Webcontent\n" > index.html
ansible all -m copy -a "src=index.html dest=/usr/share/nginx/html/index.html mode=0644"
```

4. Start and enable `nginx`:

```
ansible all -m systemd -a "name=nginx state=started enabled=true"
```

5. Verify service is running:

```
ansible all -m shell -a "curl -s localhost"
```

**Exercise:**

1. Ping all hosts.
2. Install `nginx` package.
3. Copy a custom index.html to `/usr/share/nginx/html/`.
4. Start and enable the `nginx` service.
5. Verify service is running with `curl -s localhost`.
   `-s` is for silent mode to suppress statistics

---
> [!TIP]
> With ad-hoc commands, you can quickly **test, configure, and troubleshoot** systems.  
> For more complex workflows, you’ll want to use **Ansible Playbooks**.
