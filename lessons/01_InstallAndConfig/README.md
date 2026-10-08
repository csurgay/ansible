# Section 1. Provisioning the Training Lab

### In this section the following subjects will be covered:

1.	Launch Training-Lab containers
2.	Set up SSH keys 
3.	Set up Ansible
4.	Smoke test

> [!NOTE]
> All steps of this section are automated by `labenv/run.sh` (see the main [README](../../README.md)).
> They are listed here so that you understand **what** the automation does and can fix it when something breaks
> (see [02_TroubleshootConfig](../02_TroubleshootConfig/README.md)). If your lab is already running, just read along.

### Ansible Training Environment

![Figure 1. Training lab environment](https://csurgay.com/ansible/labenv.png)

---
## Launch Training-Lab containers

Launch Ansible Control Node and three Managed Hosts in containers.

### Log into the builder environment

1.	Log in to the Ansible Training virtual machine called “builder”
2.	`su` yourself (or **`sudo -s`** with no root password) to privileged
3.	Make yourself nopasswd sudo by **`echo "<username> ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/<username>`**
4.	Install “git” if not already installed **`dnf -y install git`**
5.	Exit privileged by **`exit`** or (ctrl-d)
6.	Clone the Training Lab Git Repository to your local VM as your regular user into your home directory:
7.	**`git clone https://github.com/csurgay/ansible.git`**
8.	Change dir into the **`cd /home/<username>/ansible/labenv`** directory

### Build ansible image

> [!NOTE]
> This step is going to take quite a while, so it is prepared in advance. **Participants can skip this section!**

1.	cd into the `build_image` directory under `labenv`
2.	Run the command **`sudo ./build_image.sh`**
3.	Check the images with the command **`sudo podman images -a`**

You should see the images list:

```bash
root@builder:~/ansible/labenv/build_image$ podman images -a
REPOSITORY                         TAG         IMAGE ID      CREATED             SIZE
docker.io/csurgay/ansible_node     latest      94a737e19025  About a minute ago  1.05 GB
registry.fedoraproject.org/fedora  latest      e78db4e34c81  3 hours ago         170 MB
```

### Run the Training-Lab containers

1.	cd into the `ansible_node` directory under `labenv`
2.	Run the command **`sudo ./run_containers.sh`**
3.	Check the running container with the command **`sudo podman ps -a`**

You should see the list of containers in `Up` state

```bash
root@builder:~/ansible/labenv/ansible_node$ podman ps -a
CONTAINER ID  IMAGE                                  COMMAND         CREATED         STATUS         PORTS                                               NAMES
51d0ad5445c6  docker.io/csurgay/ansible_node:latest  /usr/sbin/init  12 seconds ago  Up 13 seconds  0.0.0.0:2020->22/tcp, 22/tcp                        ansible
bcec1e67c6f3  docker.io/csurgay/ansible_node:latest  /usr/sbin/init  12 seconds ago  Up 12 seconds  0.0.0.0:2021->22/tcp, 0.0.0.0:8081->80/tcp, 22/tcp  host1
affd78f71de7  docker.io/csurgay/ansible_node:latest  /usr/sbin/init  11 seconds ago  Up 12 seconds  0.0.0.0:2022->22/tcp, 0.0.0.0:8082->80/tcp, 22/tcp  host2
8ae3f09469ac  docker.io/csurgay/ansible_node:latest  /usr/sbin/init  11 seconds ago  Up 12 seconds  0.0.0.0:2023->22/tcp, 0.0.0.0:8083->80/tcp, 22/tcp  host3
```

---
## Set up SSH keys

Set up SSH keys so that Ansible Control Node can manage itself and Managed Hosts by SSH.

> [!NOTE]
> This section is automated in `labenv/ansible_node/setup_ssh/setup_devops.sh`. To avoid subsequent manual repetition,
> run it with `sudo ./setup_devops.sh` from its own directory.

### Create `devops` user in Control Node and Managed Hosts containers

1.	Enter Control Node with the command **`sudo podman exec -it ansible bash`**
2.  Now you entered the `ansible` container as `root`
3.  Create `devops` user by **`adduser devops`**
4.  Add password `devops` for user `devops` by **`passwd devops`** and enter `devops` twice
5.  Add `sudo` rights to `devops` by **`echo "devops ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/devops`**
6.  Exit container by **`exit`** (or ctrl-d)
7.  Repeat above points 1-5 for the three Managed Hosts by entering them with **`sudo podman exec -it host1 bash`** (then host2, host3)

### Generate devops SSH keys on Control Node

1.	Enter Control Node with the command **`sudo podman exec -it -u devops ansible bash`**
2.	Generate SSH keys with the command **`ssh-keygen -t rsa -b 4096`** (the same key type `setup_devops.sh` creates, `~/.ssh/id_rsa`)
3.	Answer with empty **`Enter`** to all three questions

### Copy devops SSH public keys into Control Node and Managed Hosts

1.	Still as `devops` in the Control Node container `ansible`
2.	Copy SSH key into localhost by **`ssh-copy-id localhost`**
3.	Copy SSH key into the first Managed Host by **`ssh-copy-id host1`**
4.	No need to answer “yes” for the known_host fingerprint related question due to ssh configuration (`StrictHostKeyChecking no`)
5.	Type in the password of user `devops` (**`devops`**) when requested
6.	Repeat 3-5 for the other two managed host containers as well

---
## Set up Ansible

Install and configure Ansible in the Control Node container.

### Install ansible, git and vim

These packages are already part of the `ansible_node` image, so in the lab this is only a check.
On a fresh host you would install them like this:

1.  Enter Ansible Control Node container `ansible` by **`sudo podman exec -it -u devops ansible bash`**
2.	Run **`sudo dnf install -y ansible git vim`** on Control Node “ansible” host
3.	Test the installation with **`ansible --version`**

### Clone Lessons git repo

Clone Training-Lab Lessons git repo into Ansible Control Node.

1.  Enter Control Node container `ansible` by **`sudo podman exec -it -u devops -w /home/devops ansible bash`**
2.  Clone the Training-Lab git repo as user `devops` under `/home/devops` by
3.  **`git clone https://github.com/csurgay/ansible.git`**

> [!NOTE]
> The reason we clone the git repo twice is that both the `labenv` for VM `builder` and
> the `lessons` for Control Node container `ansible` are packaged into the same git repo.
> The copy on the builder VM is only used to start the lab, all exercises are done in the copy inside `ansible`.

### Configure Ansible

1. Change dir **`cd /home/devops/ansible/labenv`** for ansible config creation

2.	Create a textfile named **`host_inventory`** as follows:

```ini
[controlnode]
localhost

[myhosts]
host1
host2
host3
```

3.	Create a textfile named **`ansible.cfg`**

It will contain the reference for the default inventory,
a reference for the log_path to log all ansible output to,
suppress a python related warning for convenience,
and switch the output to the more readable YAML format.

```ini
[defaults]
inventory = ./host_inventory
remote_user = devops
ask_pass = false
log_path = ./ansible.log
interpreter_python = /usr/bin/python3
callback_result_format = yaml

[privilege_escalation]
become = true
become_method = sudo
become_user = root
become_ask_pass = false
```

---
## Smoke test

Smoke test Ansible can access Managed Hosts

### Ad-hoc command for testing

1.  Enter Ansible Control Node container `ansible` by
2.  **`sudo podman exec -it -u devops -w /home/devops/ansible/labenv ansible bash`**
3.	As user `devops` inside Control Node `ansible` test Python is installed by
4.	**`ansible localhost -m setup | grep python_version`** 
5.	Test that ansible can manage the hosts with the ping module as follows:
6.	**`ansible all -m ping`** or
7.	**`ansible all -m shell -a whoami --become`** to test sudo on managed hosts without password as well
8.	Check ansible output for all four pong responses (localhost and host1..host3)

