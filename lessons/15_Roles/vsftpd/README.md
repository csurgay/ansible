# vsftpd project

Ansible automated setup of two vsftpd FTP servers (`host1`, `host2`) and one lftp client (`host3`),
written as plain Playbooks. In [vsftpd-role](../vsftpd-role/README.md) the same project is converted into a Role.

| File | Purpose |
|------|---------|
| `site.yml` | Main Playbook: imports the two Playbooks below with `import_playbook` |
| `vsftpd.yml` | Installs, configures (template) and starts vsftpd, opens the firewall, handler restarts vsftpd |
| `ftpclients.yml` | Installs the `lftp` client |
| `vars/vars.yml` | Package, service, config file names and the passive port range |
| `templates/vsftpd.conf.j2` | vsftpd configuration (passive ports come from `vars.yml`) |

`import_playbook` simply inserts the Plays of another Playbook file at that point: `site.yml` is the usual name of
the Playbook that builds the whole site.

## Run setup

```bash
ansible-playbook site.yml
```

## Testing

```bash
ssh host3

lftp -u devops host1
password: devops

cd /etc
get vimrc
bye
```

`vimrc` is now in the current directory on host3.
