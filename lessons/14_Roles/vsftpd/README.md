# vsftpd project

Ansible automated setup of two vsftpd 'ftp' servers and one lftp client

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

exit (ctrl-d)
```

