# Section 2. Troubleshooting Ansible Configuration

### In this section the following subjects will be covered:

1. Summary of setting up Ansible
1. Exercise for pairs of participants
1. Validation process for Ansible configuration

---
## Summary of setting up Ansible

- [ ] Install Ansible on Control Node
- [ ] Install Python3 all Nodes
- [ ] Create technical user on all Nodes
- [ ] Create password for technical user
- [ ] Grant sudo for technical user
- [ ] Create SSH Key for technical user on Control Node
- [ ] Copy SSH Key from Control Node to all Managed Hosts
- [ ] Create some ./inventory
- [ ] Optionally create some ./ansible.cfg
- [ ] Test Ansible can access Managed Hosts

---
## Exercise for pairs of participants

1. Participants are instructed to form group of pairs
1. One member shall introduce some failure to the Ansible configuration
1. Failures can affect any of the boxes on the Figure below
1. The other member shall try to localize and fix the failure introduced
1. The first member observes the process and helps with hints if neccessary
1. They test Ansible successfully access managed hosts together
1. Members of the pair swith roles and do the excercise again



## Figure 1. Validation process for Ansible configuration

```mermaid
flowchart TD
  subgraph id1[Ansible on control node]
    direction LR
    id11(ansible) --> id12(ansible.cfg) --> id13(inventory) --> id14(/etc/hosts)
  end
  subgraph id2[SSH on control node]
    direction LR
    id21(ssh) --> id22(ssh_config) --> id23(HostKey)
  end
  subgraph id3[SSHD on managed host]
    direction LR
    id31(sshd installed) --> id32(sshd started) --> id33(sshd config) --> id34(PermitRootLogin)
  end
  subgraph id4[Technical User]
    direction LR
    id41(user created on ControlNode) --> id42(user created on ManagedHosts) --> id43(user has password) --> id44(user has sudo)
  end
  subgraph id5[SSH Keys]
    direction LR
    id51(create Keys on ControlNode) --> id52(copy Keys to ManagedHosts)
  end
  subgraph id6[Python]
    direction LR
    id61(python3 on ControlNode) --> id62(python3 on ManagedHosts)
  end
  id1 --> id2
  id2 --> id3
  id3 --> id4
  id4 --> id5
  id5 --> id6
```

## Validation steps for Ansible configuration

| No | Failure point | Description | Test | Fix |
|----| ---------------|-------------|------|-----|
| 1 | **Ansible** | Ansible is installed on Control node | **`ansible --version`** | **`dnf install -y ansible`** |
| 2 | **ansible.cfg** | Ansible config is in place | **`ansible --version`** | **`dnf install -y ansible`** |
| 3 | **inventory** | Ansible inventory is in place | **`ansible-inventory -i inventory --list`** | Edit inventory |
| 4 | **/etc/hosts** | Hosts file contains managed IPs | **`cat /etc/hosts`** | Edit /etc/hosts |
| 5 | **ssh** | ssh is installed | see /usr/bin/ssh | **`dnf install openssh-clients`** |
| 6 | **ssh config** | ssh config is in place | see /etc/ssh/ssh_config | **`cat /etc/ssh/ssh_config`** |
| 7 | **HostKey** | of Managed hosts on Control node | see /etc/ssh/ssh_config for | **`StrictHostKeyChecking no`** | 
| 8 | **sshd installed** | on all Managed hosts | **`systemctl status sshd`** | **`dnf install openssh`** |
| 9 | **sshd started** | on all Managed hosts | **`systemctl status sshd`** | **`systemctl enable --now sshd`** |
| 10 | **sshd config** | root login enabled | see /etc/ssh/sshd_config for | **`PermitRootLogin yes`** |
| 11 | **python** | Python3 is installed on Managed hosts | see /usr/bin/python3 | **`dnf install python3`** |


