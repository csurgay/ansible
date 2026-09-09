# Users

### In this lesson the following subjects are covered

1. Install prerequisite packages with `dnf` and `pip`
1. Run a task once, delegated to the Control Node
1. Create multiple users from a loop of dictionaries
1. Store user passwords in an Ansible Vault file
1. Hash passwords and force a password change
1. Copy an SSH public key to a Managed Host

---
## Install prerequisite packages with dnf and pip

Managing Linux users with hashed passwords needs the `passlib` Python library on the machine that computes the hash, plus `libpwquality`/`cracklib-dicts` on every Managed Host for password strength checking. `ansible.builtin.dnf` installs system packages, `ansible.builtin.pip` installs Python packages.

---
## Run a task once, delegated to the Control Node

`delegate_to: localhost` redirects a task's execution from the current Managed Host to another host — here, to the Control Node itself, since that's where the `password_hash` filter used later actually needs `passlib` installed, not on the Managed Hosts. `run_once: true` stops the loop that would otherwise run the same delegated task again for every Managed Host in `hosts: all` — it only needs to happen a single time.

#### 01-setup.yml
```yaml
---
- name: Set up pip and passlib
  hosts: all
  gather_facts: false
  become: true

  tasks:

    - name: Install pip with dnf
      ansible.builtin.dnf:
        name:
          - python3
          - python3-pip
          - python3-setuptools
          - python3-packaging
        state: present
      delegate_to: localhost
      run_once: true

    - name: Install passlib with pip
      ansible.builtin.pip:
        name: passlib
        state: present
      delegate_to: localhost
      run_once: true

    - name: Install cracklib/pwquality
      ansible.builtin.dnf:
        name:
          - libpwquality
          - cracklib-dicts
        state: present
```

---
## Running the Playbook

```bash
ansible-playbook 01-setup.yml
```

---
## Store user passwords in an Ansible Vault file

`vars_files` loads variables from an external file — here `passwords.yml`, which holds `pwd_alice`, `pwd_bob` and `pwd_charlie` but is itself encrypted with `ansible-vault` (note the `$ANSIBLE_VAULT;1.1;AES256` header). Keeping real passwords out of the plaintext Playbook, and out of Git history in readable form, is exactly the problem Vault solves.

---
## Create multiple users from a loop of dictionaries

`users_to_create` is a list of dictionaries, one per user, each carrying its own name, password variable, comment, shell and home directory. Looping `ansible.builtin.user` over that list creates all three accounts from a single task instead of three near-identical ones.

---
## Hash passwords and force a password change

`{{ item.pwd | password_hash('sha512') }}` runs the plaintext password from Vault through the `password_hash` Jinja2 filter (backed by `passlib`, which is why it had to be installed on the Control Node in the setup step) before it ever reaches the Managed Host — only the hash is sent, never the plaintext.

`chage -d 0 {{ item.name }}` sets each account's last-password-change date to the epoch, which forces the user to set a new password the next time they log in — a common practice for freshly provisioned accounts.

#### 02-create.yml
```yaml
---
- name: Create three local users on all servers
  hosts: all
  gather_facts: false
  become: true
  vars_files:
    - "passwords.yml"

  vars:
    users_to_create:

      - name: "alice"
        pwd: "{{ pwd_alice }}"
        comment: "Alice User"
        shell: "/bin/bash"
        home: "/home/alice"

      - name: "bob"
        pwd: "{{ pwd_bob }}"
        comment: "Bob User"
        shell: "/bin/bash"
        home: "/home/bob"

      - name: "charlie"
        pwd: "{{ pwd_charlie }}"
        comment: "Charlie User"
        shell: "/bin/bash"
        home: "/home/charlie"

  tasks:

    - name: Create local users
      ansible.builtin.user:
        name: "{{ item.name }}"
        password: "{{ item.pwd | password_hash('sha512') }}"
        comment: "{{ item.comment }}"
        shell: "{{ item.shell }}"
        home: "{{ item.home }}"
        create_home: true
        state: present
      loop: "{{ users_to_create }}"

    - name: Force password change
      ansible.builtin.shell:
        cmd: "chage -d 0 {{ item.name }}"
      loop: "{{ users_to_create }}"
```

---
## Running the Playbook

Because `passwords.yml` is Vault-encrypted, Ansible needs the Vault password before it can decrypt it — `--vault-id=@prompt` asks for it interactively:

```bash
ansible-playbook --vault-id=@prompt 02-create.yml
```

---
## Copy an SSH public key to a Managed Host

`ansible.posix.authorized_key` adds a public key to a user's `~/.ssh/authorized_keys` file, so that user can log in with that key without a password. `lookup('file', ...)` reads the key's contents from a file on the Control Node at Play time, so the key itself never needs to be hardcoded into the Playbook.

#### 03-copysshid.yml
```yaml
---
- name: copy-ssh-id to Managed Host
  hosts: myhosts
  become: true
  gather_facts: false

  tasks:

    - name: copy-ssh-id to Managed Host
      ansible.posix.authorized_key:
        user: 'bob'
        state: present
        key: "{{ lookup('file', '/home/devops/.ssh/id_ed25519.pub') }}"
```

---
## Running the Playbook

```bash
ansible-playbook 03-copysshid.yml
```

After this runs, you should be able to `ssh bob@host1` using the key that was copied in, without being prompted for `bob`'s password.
