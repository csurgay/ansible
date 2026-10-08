# Section 11. Vault

### In this section the following subjects will be covered:

1. Introduction to Secrets
1. Vault Usage
1. Vault in Playbooks
1. Encrypting a single variable
1. Keeping secrets out of the output

---
### Introduction to Secrets

Automation tasks require credentials. Passwords, SSH and API keys, tokens need to be used on the
Managed Hosts for resources to be managed. These cannot be stored in plain text in Playbooks or
other text files (and certainly not in Git) for obvious security reasons.

Ansible Vault encrypts files (or single values) with AES256 using a vault password, and Ansible decrypts them
automatically when a Playbook needs them. Vault can encrypt variable files (structured Ansible data in YAML
format) as well as any other data file.

---
### Vault Usage

```bash
ansible-vault create mysecret.yml
```

The command asks for a new vault password and opens the text editor (`$EDITOR`, default `vi`) for the
structured data to be encrypted, e.g.:

```yaml
---
# Secrets to be encrypted by Vault
username: devops
password: devops
```

The encrypted `mysecret.yml` of this directory contains exactly this, its vault password is **`secret`**.

Other operations:

```bash
ansible-vault view mysecret.yml
ansible-vault edit mysecret.yml
ansible-vault decrypt mysecret.yml --output=mysecret-decrypted.yml
ansible-vault rekey mysecret.yml          # change the vault password
ansible-vault encrypt somefile.yml        # encrypt an existing plaintext file in place
ansible-vault decrypt somefile.yml        # ... and back
```

The vault password can also be stored in a file, with appropriate access control of course
(`chmod 600`, and never commit it to Git — in this training repo it is committed only for convenience):

```bash
echo secret > vault-pass.yml
chmod 600 vault-pass.yml
ansible-vault view --vault-password-file=vault-pass.yml mysecret.yml
```

(The file name does not matter, it is plain text, not YAML; `.vault_pass` is a common name.)

---
### Vault in Playbooks

Variables from Vault-encrypted files are used as usual, e.g. with `vars_files: mysecret.yml`, as long as
Ansible gets the vault password:

```bash
ansible-playbook --vault-id=@prompt test.yml                  # prompt for the password
ansible-playbook --ask-vault-pass test.yml                    # the same, older option
ansible-playbook --vault-password-file=vault-pass.yml test.yml  # read it from a file
```

#### test.yml
```yaml
---
- name: Vault Variable illustration
  hosts: host1
  gather_facts: false
  vars_files:
    - mysecret.yml
  tasks:
    - name: Print encrypted variables from Vault
      ansible.builtin.debug:
        msg:
          - "username: {{ username }}"
          - "password: {{ password }}"
      # no_log: true # would prevent the secret from being printed and logged
```

Vault protects secrets **at rest** (in files, in Git). Once decrypted, a variable is a normal variable: the
Playbook above happily prints the password. Uncomment `no_log: true` and run it again.

---
### Encrypting a single variable

Instead of encrypting a whole file, single values can be encrypted and pasted into an otherwise readable YAML file:

```bash
ansible-vault encrypt_string --vault-password-file=vault-pass.yml 'devops' --name 'db_password'
```

```yaml
db_password: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          6263643562386264...
```

---
### Keeping secrets out of the output

- `no_log: true` on a task hides its arguments and results from the output and `ansible.log`
- with loops, `loop_control: label: "{{ item.name }}"` prints only a harmless part of the loop item
- never use `-v`/`-vvv` with secrets in shared logs

See [14_LinuxAdminLabs/06-users](../14_LinuxAdminLabs/06-users/README.md) for a real-life use: user passwords
stored in a Vault file.
