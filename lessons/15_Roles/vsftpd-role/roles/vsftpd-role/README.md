vsftpd-role
===========

Sets up vsftpd FTP servers (hosts of group `ftpservers`) and lftp clients (hosts of group `ftpclients`),
opens the FTP port and the passive data ports in firewalld.

Requirements
------------

Fedora/RHEL hosts with `firewalld`, collection `ansible.posix`.

Role Variables
--------------

In `vars/main.yml`:

| Variable | Default | Description |
|----------|---------|-------------|
| `vsftpd_package` | `vsftpd` | Package to install |
| `vsftpd_service` | `vsftpd` | Service name |
| `vsftpd_config_file` | `/etc/vsftpd/vsftpd.conf` | Config file deployed from `templates/vsftpd.conf.j2` |
| `vsftpd_pasv_min_port` / `vsftpd_pasv_max_port` | `21000` / `21020` | Passive data port range |

Example Playbook
----------------

    - hosts: ftpservers:ftpclients
      become: true
      roles:
        - vsftpd-role

License
-------

MIT
