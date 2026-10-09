# Section 20: Managing Windows Hosts

#### In this section the following subjects will be covered:

1. How Ansible talks to Windows (WinRM, PSRP, SSH)
1. Preparing the Control Node and the Windows host
1. Inventory variables for Windows
1. Windows modules (`ansible.windows`, `community.windows`)
1. Examples: ping and facts, IIS webserver, users and groups, configuration, updates
1. Differences from Linux you must remember

> [!IMPORTANT]
> The bootcamp lab has **no Windows Managed Host** (the lab containers are Linux only). Run these examples against
> your own Windows VM or server (e.g. a Windows Server 2022 evaluation VM) that the Control Node can reach, or follow
> them as an instructor demo. All Playbooks pass `ansible-playbook --syntax-check`.

---
## How Ansible talks to Windows

On Linux Ansible connects with SSH and runs **Python** modules. On Windows there is no Python: the Windows modules
are written in **PowerShell**. The Control Node still has to be Linux/Unix (on a Windows PC run Ansible in WSL).
There are three connection plugins:

| `ansible_connection` | Protocol | Port | Notes |
|----------------------|----------|------|-------|
| `winrm` | WinRM (WS-Management) | 5985 HTTP, 5986 HTTPS | The classic choice, needs `pywinrm` on the Control Node |
| `psrp` | PowerShell Remoting Protocol over WinRM | 5985 / 5986 | Faster, needs `pypsrp` |
| `ssh` | OpenSSH | 22 | Official since ansible-core 2.18; needs Windows Server 2022+ (OpenSSH 7.9+) and `ansible_shell_type=powershell` |

WinRM authentication (`ansible_winrm_transport`):

| Transport | Use it when |
|-----------|-------------|
| `kerberos` | The host is in an Active Directory domain: **the company standard** |
| `ntlm` | Local accounts, workgroup hosts (lab) |
| `basic` | Only for tests, only over HTTPS: the password is sent base64 encoded |
| `credssp` | Only if you need credential delegation (second hop); avoid otherwise |

> [!NOTE]
> In a company environment WinRM, its HTTPS certificates and the firewall rules are usually set up centrally with
> Group Policy, and Ansible logs in with a domain service account over Kerberos. Ask the Windows team before
> enabling anything by hand.

---
## Preparing the Control Node

```bash
# the Python library for WinRM (Fedora package or pip)
sudo dnf install python3-winrm        # or: pip install pywinrm

# the Windows collections (ansible.windows is also part of the full "ansible" package)
ansible-galaxy collection install ansible.windows community.windows
```

## Preparing the Windows host (lab only)

[setup-winrm.ps1](setup-winrm.ps1) does the minimum for a lab VM, run it in an elevated PowerShell:

1. `Enable-PSRemoting -Force`: starts WinRM and creates the HTTP listener (5985)
1. creates a self-signed certificate and an HTTPS listener (5986)
1. opens port 5986 in the Windows firewall
1. sets `LocalAccountTokenFilterPolicy` so that a **local** administrator gets full rights over WinRM

Check it from the Windows side with `winrm enumerate winrm/config/Listener`, and from the Control Node with
`curl -k https://<windows-ip>:5986/wsman` (an HTTP 405 or 401 answer means the listener is up).

---
## Inventory variables for Windows

#### host_inventory
```ini
[windows]
win1 ansible_host=192.168.56.50

[windows:vars]
ansible_user=Administrator
ansible_connection=winrm
ansible_port=5986
ansible_winrm_scheme=https
ansible_winrm_transport=ntlm
ansible_winrm_server_cert_validation=ignore
```

`ansible_winrm_server_cert_validation=ignore` is needed only because of the self-signed lab certificate. With
certificates from the company CA leave it out (the default is `validate`).

The password is not in the inventory: [ansible.cfg](ansible.cfg) has `ask_pass = true`, so Ansible asks for it.
For unattended runs put it in a Vault-encrypted group variable file instead ([Section 11](../11_Vault/README.md)):

```bash
mkdir -p group_vars/windows
ansible-vault create group_vars/windows/vault.yml      # ansible_password: "..."
ansible-playbook win_ping.yml --ask-vault-pass
```

The same host over SSH: [host_inventory_ssh](host_inventory_ssh)
```ini
[windows:vars]
ansible_user=Administrator
ansible_connection=ssh
ansible_shell_type=powershell
```

> [!NOTE]
> There is no `become: true` with `sudo` on Windows. The WinRM user is usually already an administrator; if a task
> must run as another user (e.g. `SYSTEM`) use `become_method: runas`.

---
## Windows modules

The Linux modules (`ansible.builtin.copy`, `service`, `user`, `file`, `template`, `command`, `ping`...) **do not work
on Windows**. Use the `win_` modules from the `ansible.windows` collection (supported by Red Hat) and from
`community.windows` (community maintained). A few modules work on both: `ansible.builtin.debug`, `set_fact`,
`assert`, `fail`, `include_tasks`... (they run on the Control Node), and `ansible.builtin.setup` (fact gathering).

| Linux | Windows |
|-------|---------|
| `ansible.builtin.ping` | `ansible.windows.win_ping` |
| `ansible.builtin.package` / `dnf` | `ansible.windows.win_package` (MSI/EXE), `win_feature` (roles & features), `chocolatey.chocolatey.win_chocolatey` |
| `ansible.builtin.service` | `ansible.windows.win_service` |
| `ansible.builtin.copy` / `template` / `file` | `ansible.windows.win_copy` / `win_template` / `win_file` |
| `ansible.builtin.lineinfile` | `ansible.windows.win_lineinfile` |
| `ansible.builtin.user` / `group` | `ansible.windows.win_user` / `win_group` / `win_group_membership` |
| `ansible.builtin.command` / `shell` | `ansible.windows.win_command` / `win_shell` / `win_powershell` |
| `ansible.builtin.reboot` | `ansible.windows.win_reboot` |
| `ansible.builtin.uri` / `get_url` | `ansible.windows.win_uri` / `win_get_url` |
| `ansible.posix.firewalld` | `community.windows.win_firewall_rule` |
| (no equivalent) | `ansible.windows.win_regedit` (registry), `win_updates` (Windows Update), `win_dsc` (DSC resources) |

```bash
ansible-doc -l ansible.windows             # list the modules
ansible-doc ansible.windows.win_service    # documentation with examples
```

---
## Example 1: ping and facts

#### win_ping.yml
```yaml
---
- name: Test the connection to the Windows hosts
  hosts: windows
  gather_facts: true

  tasks:
    - name: Ping (ansible.builtin.ping does NOT work on Windows)
      ansible.windows.win_ping:

    - name: Show a few facts
      ansible.builtin.debug:
        msg: >-
          {{ ansible_facts['hostname'] }} runs {{ ansible_facts['os_name'] }}
          ({{ ansible_facts['distribution_version'] }}),
          {{ ansible_facts['memtotal_mb'] }} MB RAM
    ...
```

```bash
ansible-playbook win_ping.yml                     # asks for the password
ansible windows -m ansible.windows.win_ping       # the same Ad-Hoc
ansible windows -m ansible.windows.win_shell -a 'Get-Service W3SVC'
ansible windows -m ansible.builtin.setup -a 'filter=ansible_os*'
```

---
## Example 2: IIS webserver

The Windows version of our Linux webserver Playbooks: feature, service, page from a template, firewall, test.

#### iis.yml
```yaml
---
- name: Install and configure IIS
  hosts: windows
  gather_facts: true
  vars:
    web_root: C:\inetpub\wwwroot
    web_port: 80

  tasks:
    - name: Install the IIS Windows feature
      ansible.windows.win_feature:
        name: Web-Server
        include_management_tools: true
        state: present
      register: iis

    - name: Reboot if the feature installation needs it
      ansible.windows.win_reboot:
      when: iis.reboot_required

    - name: Make sure the IIS service runs and starts at boot
      ansible.windows.win_service:
        name: W3SVC
        state: started
        start_mode: auto

    - name: Deploy the start page from a template
      ansible.windows.win_template:
        src: templates/index.html.j2
        dest: '{{ web_root }}\index.html'

    - name: Open the firewall for HTTP
      community.windows.win_firewall_rule:
        name: HTTP (Ansible)
        localport: "{{ web_port }}"
        protocol: tcp
        direction: in
        action: allow
        state: present
        enabled: true

    - name: Test the page from the Windows host itself
      ansible.windows.win_uri:
        url: "http://localhost:{{ web_port }}/"
        return_content: true
      register: page
      failed_when: "'Ansible' not in page.content"
```

Run it twice: the second run reports `changed=0`, the `win_` modules are idempotent just like the Linux ones.

> [!TIP]
> **Backslashes in YAML.** `C:\inetpub\wwwroot` is fine unquoted or in **single** quotes. In **double** quotes the
> backslash is an escape character (`"C:\temp"` contains a TAB character!): write `"C:\\temp"` or use single quotes.
> Most `win_` modules also accept forward slashes: `C:/inetpub/wwwroot`.

---
## Example 3: local users and groups

#### users.yml (excerpt)
```yaml
  vars_prompt:
    - name: initial_password
      prompt: Initial password for the new users (must meet the Windows complexity rules)
      private: true
  vars:
    win_users:
      - name: alice
        fullname: Alice Admin
        groups: [Administrators]
      - name: bob
        fullname: Bob Operator
        groups: [AppOperators, "Remote Desktop Users"]

  tasks:
    - name: Create the local group
      ansible.windows.win_group:
        name: AppOperators
        state: present

    - name: Create the users
      ansible.windows.win_user:
        name: "{{ item.name }}"
        fullname: "{{ item.fullname }}"
        password: "{{ initial_password }}"
        update_password: on_create      # do not reset the password on every run
        password_expired: true          # must be changed at first logon
        groups: "{{ item.groups }}"
        groups_action: add              # add to these groups, keep the others
        state: present
      loop: "{{ win_users }}"
      loop_control:
        label: "{{ item.name }}"
      no_log: true
```

Unlike `ansible.builtin.user`, `win_user` takes the password in **clear text** (Windows hashes it), so no
`password_hash` filter is needed; protect it with `vars_prompt` or Vault and `no_log`.
Domain users and groups are managed with the `microsoft.ad` collection.

---
## Example 4: typical configuration tasks

[config.yml](config.yml) shows the modules you will use most often besides the above:

| Task | Module |
|------|--------|
| Create a directory | `ansible.windows.win_file` with `state: directory` |
| Write a config file | `ansible.windows.win_copy` with `content:` |
| Registry value | `ansible.windows.win_regedit` (`path: HKLM:\...`, `name`, `data`, `type: dword`) |
| Time zone | `ansible.windows.win_timezone` |
| Environment variable | `ansible.windows.win_environment` with `level: machine` |
| Anything else | `ansible.windows.win_powershell` |

#### `win_command` vs `win_shell` vs `win_powershell`
The same rule as on Linux: prefer a dedicated module. If there is none:
- `win_command` runs an executable **without** a shell (no pipes, no variables), like `ansible.builtin.command`
- `win_shell` runs the text in PowerShell (or `cmd` with `executable: cmd`) and is **always** `changed`
- `win_powershell` runs a script and lets **the script** say whether it changed something, so it can be idempotent:

```yaml
    - name: Run PowerShell and report changes correctly
      ansible.windows.win_powershell:
        script: |
          $svc = Get-Service -Name Spooler
          if ($svc.StartType -ne 'Disabled') {
              Set-Service -Name Spooler -StartupType Disabled
              Stop-Service -Name Spooler -Force
              $Ansible.Changed = $true
          } else {
              $Ansible.Changed = $false
          }
```

---
## Example 5: Windows updates

#### updates.yml
```yaml
---
- name: Install Windows updates
  hosts: windows
  gather_facts: false
  serial: 1                       # one server at a time, as with a rolling update

  tasks:
    - name: Install security and critical updates, reboot if needed
      ansible.windows.win_updates:
        category_names:
          - SecurityUpdates
          - CriticalUpdates
        reboot: true
      register: upd

    - name: Report
      ansible.builtin.debug:
        msg: "{{ upd.installed_update_count }} updates installed, reboot needed: {{ upd.reboot_required }}"
```

Run `ansible-playbook updates.yml --check` first: in check mode `win_updates` only lists what it would install.
`serial` works exactly as in the rolling update of [Section 12](../12_ControlFlow/README.md).

---
## Differences from Linux you must remember

| | Linux | Windows |
|---|---|---|
| Connection | SSH with key | WinRM (or SSH) with password / Kerberos |
| Modules written in | Python | PowerShell |
| Privilege | `become: true` (sudo) | the login user is admin; `become_method: runas` if needed |
| Paths | `/etc/app.conf` | `C:\App\app.ini` (mind the quotes) |
| Packages | `dnf` repositories | `win_feature`, MSI/EXE with `win_package`, Chocolatey |
| Reboot | rare | frequent (features, updates): `reboot_required` + `win_reboot` |
| Case | file names are case sensitive | not case sensitive |

---
## Exercise

1. Run `win_ping.yml`, then the Ad-Hoc `ansible windows -m ansible.builtin.setup` and find the Windows version in the facts.
1. Run `iis.yml` twice and open `http://<windows-ip>/` in a browser. Change the template and run it again.
1. Extend `users.yml` with a third user that is only a member of `AppOperators`.
1. Write a task that ensures the `Telnet-Client` feature is **absent**. Run it with `--check --diff` first.

---
#### Further reading
- [Managing Windows hosts with Ansible](https://docs.ansible.com/ansible/latest/os_guide/intro_windows.html)
- [Windows Remote Management](https://docs.ansible.com/ansible/latest/os_guide/windows_winrm.html), [Windows SSH](https://docs.ansible.com/ansible/latest/os_guide/windows_ssh.html)
- [ansible.windows collection](https://docs.ansible.com/ansible/latest/collections/ansible/windows/index.html)
