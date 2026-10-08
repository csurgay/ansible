# Users

### In this lesson the following subjects are covered

1. Install a prerequisite package on the Control Node with `delegate_to` and `run_once`
1. Create multiple users from a loop of dictionaries
1. Store user passwords in an Ansible Vault file
1. Hash passwords idempotently and force a password change for new users only
1. Keep secrets out of the output with `loop_control: label`
1. Copy an SSH public key to a Managed Host

<img width="2720" height="2024" alt="users_lesson_flow" src="https://github.com/user-attachments/assets/4a639c1d-06fc-4d94-9bc4-227b9cd96794" />

> [!NOTE]
> This lab uses [11_Vault](../../11_Vault/README.md): the Vault password of `passwords.yml` is **`secret`**.

---
## Install a prerequisite on the Control Node

The `password_hash` Jinja2 filter used later needs the `passlib` Python library — on the **Control Node**,
because templating (and so hashing) happens there, not on the Managed Hosts.

`delegate_to: localhost` redirects a task's execution from the current Managed Host to another host — here,
to the Control Node itself. `run_once: true` stops the same delegated task from running again for every
Managed Host in the Play — it only needs to happen a single time.

#### 01-setup.yml
```yaml
---
- name: Install passlib on the Control Node
  hosts: myhosts
  gather_facts: false
  become: true

  tasks:

    - name: Install passlib with dnf (needed by the password_hash filter)
      ansible.builtin.dnf:
        name: python3-passlib
        state: present
      delegate_to: localhost
      run_once: true
```

```bash
ansible-playbook 01-setup.yml
```

---
## Store user passwords in an Ansible Vault file

`vars_files` loads variables from an external file — here `passwords.yml`, which holds `pwd_alice`, `pwd_bob`
and `pwd_charlie` but is itself encrypted with `ansible-vault` (note the `$ANSIBLE_VAULT;1.1;AES256` header).
Keeping real passwords out of the plaintext Playbook, and out of Git history in readable form, is exactly the
problem Vault solves. Look inside with:

```bash
ansible-vault view passwords.yml
```

---
## Create multiple users from a loop of dictionaries

`users_to_create` is a list of dictionaries, one per user, each carrying its own name, password variable,
comment, shell and home directory. Looping `ansible.builtin.user` over that list creates all three accounts
from a single task instead of three near-identical ones.

### Don't print the passwords: loop_control label

By default Ansible prints the whole loop item for every iteration, `(item={'name': 'alice', 'pwd': 'alice', ...})`,
which here would put the **decrypted** password on the screen and into `ansible.log`.
`loop_control: label: "{{ item.name }}"` prints only the user name. (`no_log: true` would hide everything.)

### Hash passwords idempotently

`{{ item.pwd | password_hash('sha512') }}` turns the plaintext password into a SHA-512 crypt hash before it
reaches the Managed Host. The hash contains a **random salt**, so it is different on every run — Ansible
would report every user as `changed` every time. `update_password: on_create` sets the password only when the
user is created, so a second run reports `ok`.

### Force a password change, only for new users

`chage -d 0 <user>` sets the last-password-change date to the epoch, which forces the user to set a new
password at the next login. `register: result_users` records the result of every loop iteration, and
`when: item is changed` runs `chage` only for users that were really created in this run. Without that
condition every run would expire the passwords again.

#### 02-create.yml
```yaml
---
- name: Create three local users on all servers
  hosts: myhosts
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
        update_password: on_create
        comment: "{{ item.comment }}"
        shell: "{{ item.shell }}"
        home: "{{ item.home }}"
        create_home: true
        state: present
      loop: "{{ users_to_create }}"
      loop_control:
        label: "{{ item.name }}"
      register: result_users

    - name: Force password change at first login (only for newly created users)
      ansible.builtin.command:
        cmd: "chage -d 0 {{ item.item.name }}"
      loop: "{{ result_users.results }}"
      loop_control:
        label: "{{ item.item.name }}"
      when: item is changed
```

Because `passwords.yml` is Vault-encrypted, Ansible needs the Vault password before it can decrypt it —
`--vault-id=@prompt` asks for it interactively (type `secret`):

```bash
ansible-playbook --vault-id=@prompt 02-create.yml
```

Run it twice: the second run should report `ok` for every user and skip the `chage` task.

---
## Copy an SSH public key to a Managed Host

`ansible.posix.authorized_key` adds a public key to a user's `~/.ssh/authorized_keys` file, so that user can
log in with that key without a password. `lookup('ansible.builtin.file', ...)` reads the key's contents from a
file on the Control Node at Play time, so the key itself never needs to be hardcoded into the Playbook.

#### 03-copysshid.yml
```yaml
---
- name: Copy the devops SSH public key to bob on the Managed Hosts
  hosts: myhosts
  become: true
  gather_facts: false
  vars:
    # setup_devops.sh creates an RSA key; use id_ed25519.pub if you created an ed25519 key
    ssh_pubkey_file: /home/devops/.ssh/id_rsa.pub

  tasks:

    - name: Add the key to ~bob/.ssh/authorized_keys
      ansible.posix.authorized_key:
        user: bob
        state: present
        key: "{{ lookup('ansible.builtin.file', ssh_pubkey_file) }}"
```

```bash
ansible-playbook 03-copysshid.yml
```

Now, as `devops` on the Control Node, run `ssh bob@host1`: the key is accepted and bob is logged in without a
password prompt.

To see the effect of `chage -d 0`, log in with the password instead of the key:
`ssh -o PubkeyAuthentication=no bob@host1`. Enter the current password (`bob`, from `passwords.yml`): sshd
immediately asks for a **new** password. (Whether an expired password is also enforced on key logins depends on
the sshd/PAM configuration; the minimal sshd config of the lab image enforces it on password logins only.)

`./run.sh` runs all three Playbooks in a row.
