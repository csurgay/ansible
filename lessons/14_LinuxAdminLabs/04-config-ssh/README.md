# Config, SSH

### In this lesson the following subjects are covered

1. Prompt for a variable at runtime with `vars_prompt`
1. Edit a config file in place with `lineinfile`
1. Validate a config change before applying it
1. Notify a handler only when a change occurs
1. Copy a multi-line file with the `copy` module

---
## Prompt for a variable at runtime

`vars_prompt` asks a question on the Control Node before the Play starts, and stores the answer in a variable you can use anywhere in the Play. `private: false` means the typed answer is echoed back to the terminal (use `true` for things like passwords).

```yaml
  vars_prompt:
    - name: yesorno
      prompt: PasswordAuthentication yes or no?
      private: false
```

---
## Edit a config file in place with lineinfile

`ansible.builtin.lineinfile` finds a line matching `regexp` inside the file given by `path` and replaces it with `line` — or adds the line if no match is found. This is the standard, idempotent way to change a single setting in an existing config file without touching the rest of it.

---
## Validate a config change before applying it

`validate` runs a command against a temporary copy of the file **before** Ansible overwrites the real one. `%s` is replaced by the path to that temporary copy. If the command exits non-zero, Ansible aborts and leaves the original file untouched — here `sshd -t -f %s` asks `sshd` itself to check the syntax, so a **syntax** error can never leave you with a broken SSH config.

> [!WARNING]
> `validate` only checks syntax, not whether the setting makes sense. `PasswordAuthentication no` is perfectly valid,
> and still locks out everybody who has no SSH key. In the lab, answer `yes` at the end of the exercise again,
> because later lessons (`ssh-copy-id`, user logins) rely on password authentication.
>
> On real Fedora/RHEL 9+ systems `sshd_config` starts with `Include /etc/ssh/sshd_config.d/*.conf`, and for sshd
> the **first** value of a setting wins. A drop-in file there may override what you put into `sshd_config`.
> The best practice is to deploy your own drop-in instead, e.g. `/etc/ssh/sshd_config.d/10-ansible.conf`.
> (The lab image uses a minimal `sshd_config` without the `Include`.)

The Playbook also checks the typed answer with `ansible.builtin.assert` before touching anything.

---
## Notify a handler only when a change occurs

`notify` points to a **handler**, defined separately under the Play's `handlers:` section. A handler only runs if the notifying task actually reports `changed` — if `PasswordAuthentication` was already set to the requested value, `lineinfile` makes no change and `sshd` is never restarted. Handlers also only run once, at the end of the Play, even if notified by several tasks.

#### config-ssh.yml
```yaml
---
- name: Modify sshd Configuration
  hosts: all
  become: true
  gather_facts: false
  vars_prompt:
    - name: yesorno
      prompt: PasswordAuthentication yes or no?
      private: false

  tasks:

    - name: Check the answer
      ansible.builtin.assert:
        that: yesorno in ['yes', 'no']
        fail_msg: "Please answer yes or no"

    - name: Set PasswordAuthentication
      ansible.builtin.lineinfile:
        path: /etc/ssh/sshd_config
        regexp: "^PasswordAuthentication"
        line: "PasswordAuthentication {{ yesorno }}"
        state: present
        validate: 'sshd -t -f %s'
      notify: Restart sshd

  handlers:

    - name: Restart sshd
      ansible.builtin.service:
        name: sshd
        state: restarted
```

---
## Running the Playbook

```bash
ansible-playbook config-ssh.yml
```

Ansible will pause and ask `PasswordAuthentication yes or no?` before running the Play. Run it a second time with the same answer and notice the task reports `ok` instead of `changed` — and the handler does not fire.

---
## Copy a multi-line file with the copy module

`ansible.builtin.copy` can write literal content straight into a file using the `content` key, without needing a separate source file. The `|` (block scalar) preserves line breaks exactly as written. `owner`, `group` and `mode` set the file's permissions, and `backup: true` saves a timestamped copy of any file it overwrites, so previous content is never lost.

#### copy-motd.yml
```yaml
---
- name: Create the message of the day
  hosts: all
  become: true
  gather_facts: false
  vars:
    motdfile: "/etc/motd"

  tasks:

    - name: Create /etc/motd
      ansible.builtin.copy:
        dest: "{{ motdfile }}"
        content: |
          *** Containerized Ansible Training ***
          Greetings on this Managed Host!
          Weather is nice today.
          Automation with Ansible is fun!
        owner: root
        group: root
        mode: '0644'
        backup: true
```

---
## Running the Playbook

```bash
ansible-playbook copy-motd.yml
```

Check the result with `ssh host1` from the Control Node: the new message is printed at login (`podman exec` aliases like `d1` do not show it, they are not logins).
