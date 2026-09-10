# Section 10. Facts

### In this section the following subjects will be covered:

1. Ansible Facts
1. Custom Facts

---
### Ansible Facts

`ansible host1 -m setup`  
`ansoble host1 --become --ask-become-pass -m setup`

```
---
- name: How to gather ansible facts from hosts
  hosts: host1
  gather_facts: true
  tasks:
    - name: Print ansible_facts
      ansible.builtin.debug:
        var: "{{ ansible_facts }}"
```  

```
host1 | SUCCESS => {
    "ansible_facts": {
        "ansible_all_ipv4_addresses": [
            "10.89.0.14"
        ],
        "ansible_all_ipv6_addresses": [
            "fe80::1210:10ff:fe10:1011"
        ],
        "ansible_apparmor": {
            "status": "disabled"
        },
        "ansible_architecture": "x86_64",
        "ansible_bios_date": "12/01/2006",
        "ansible_bios_vendor": "innotek GmbH",
        "ansible_bios_version": "VirtualBox",
        "ansible_board_asset_tag": "NA",
        "ansible_board_name": "VirtualBox",
        "ansible_board_serial": "NA",
        "ansible_board_vendor": "Oracle Corporation",
        "ansible_board_version": "1.2",
        "ansible_chassis_asset_tag": "NA",
        "ansible_chassis_serial": "NA",
        "ansible_chassis_vendor": "Oracle Corporation",
        "ansible_chassis_version": "NA",
        "ansible_cmdline": {
            "BOOT_IMAGE": "(hd0,gpt2)/vmlinuz-6.11.4-301.fc41.x86_64",
            "quiet": true,
            "rhgb": true,
            "ro": true,
            "root": "UUID=cd46931f-f193-41b8-854e-a34bff8cc760",
            "rootflags": "subvol=root"
        },
        "ansible_date_time": {
            "date": "2025-10-15",
            "day": "15",
            "epoch": "1760561239",
            "epoch_int": "1760561239",
            "hour": "20",
            "iso8601": "2025-10-15T20:47:19Z",
            "iso8601_basic": "20251015T204719385122",
            "iso8601_basic_short": "20251015T204719",
            "iso8601_micro": "2025-10-15T20:47:19.385122Z",
            "minute": "47",
            "month": "10",
            "second": "19",
            "time": "20:47:19",
            "tz": "UTC",
            "tz_dst": "UTC",
            "tz_offset": "+0000",
            "weekday": "Wednesday",
            "weekday_number": "3",
            "weeknumber": "41",
            "year": "2025"
        },
        "ansible_default_ipv4": {
            "address": "10.89.0.14",
            "alias": "eth0",
            "broadcast": "10.89.0.255",
            "gateway": "10.89.0.1",
            "interface": "eth0",
            "macaddress": "10:10:10:10:10:11",
            "mtu": 1500,
            "netmask": "255.255.255.0",
            "network": "10.89.0.0",
            "prefix": "24",
            "type": "ether"
        },
        "ansible_default_ipv6": {},
        "ansible_device_links": {
            "ids": {},
            "labels": {},
            "masters": {},
            "uuids": {}
        },
        "ansible_devices": {
            "sda": {
                "holders": [],
                "host": "SATA controller: Intel Corporation 82801HM/HEM (ICH8M/ICH8M-E) SATA Controller [AHCI mode] (rev 02)",
                "links": {
                    "ids": [],
                    "labels": [],
                    "masters": [],
                    "uuids": []
                },
                "model": "VBOX HARDDISK",
                "partitions": {
                    "sda1": {
                        "holders": [],
                        "links": {
                            "ids": [],
                            "labels": [],
                            "masters": [],
                            "uuids": []
                        },
                        "sectors": 2048,
                        "sectorsize": 512,
                        "size": "1.00 MB",
                        "start": "2048",
                        "uuid": null
                    },
                    "sda2": {
                        "holders": [],
                        "links": {
                            "ids": [],
                            "labels": [],
                            "masters": [],
                            "uuids": []
                        },
                        "sectors": 2097152,
                        "sectorsize": 512,
                        "size": "1.00 GB",
                        "start": "4096",
                        "uuid": null
                    },
                    "sda3": {
                        "holders": [],
                        "links": {
                            "ids": [],
                            "labels": [],
                            "masters": [],
                            "uuids": []
                        },
                        "sectors": 81782784,
                        "sectorsize": 512,
                        "size": "39.00 GB",
                        "start": "2101248",
                        "uuid": null
                    }
                },
                "removable": "0",
                "rotational": "1",
                "sas_address": null,
                "sas_device_handle": null,
                "scheduler_mode": "bfq",
                "sectors": 83886080,
                "sectorsize": "512",
                "size": "40.00 GB",
                "support_discard": "0",
                "vendor": "ATA",
                "virtual": 1
            },
            "sr0": {
                "holders": [],
                "host": "IDE interface: Intel Corporation 82371AB/EB/MB PIIX4 IDE (rev 01)",
                "links": {
                    "ids": [],
                    "labels": [],
                    "masters": [],
                    "uuids": []
                },
                "model": "CD-ROM",
                "partitions": {},
                "removable": "1",
                "rotational": "0",
                "sas_address": null,
                "sas_device_handle": null,
                "scheduler_mode": "bfq",
                "sectors": 2097151,
                "sectorsize": "512",
                "size": "1024.00 MB",
                "support_discard": "0",
                "vendor": "VBOX",
                "virtual": 1
            },
            "zram0": {
                "holders": [],
                "host": "",
                "links": {
                    "ids": [],
                    "labels": [],
                    "masters": [],
                    "uuids": []
                },
                "model": null,
                "partitions": {},
                "removable": "0",
                "rotational": "0",
                "sas_address": null,
                "sas_device_handle": null,
                "scheduler_mode": "",
                "sectors": 1000192,
                "sectorsize": "4096",
                "size": "3.82 GB",
                "support_discard": "4096",
                "vendor": null,
                "virtual": 1
            }
        },
        "ansible_distribution": "Fedora",
        "ansible_distribution_file_parsed": true,
        "ansible_distribution_file_path": "/etc/redhat-release",
        "ansible_distribution_file_variety": "RedHat",
        "ansible_distribution_major_version": "42",
        "ansible_distribution_release": "",
        "ansible_distribution_version": "42",
        "ansible_dns": {
            "nameservers": [
                "10.89.0.1"
            ],
            "search": [
                "dns.podman"
            ]
        },
        "ansible_domain": "",
        "ansible_effective_group_id": 1000,
        "ansible_effective_user_id": 1000,
        "ansible_env": {
            "GPG_TTY": "/dev/pts/0",
            "HOME": "/home/devops",
            "LANG": "C.UTF-8",
            "LOGNAME": "devops",
            "LS_COLORS": "rs=0:di=01;34:ln=01;36:mh=00:pi=40;33:so=01;35:do=01;35:bd=40;33;01:cd=40;33;01:or=40;31;01:mi=01;37;41:su=37;41:sg=30;43:ca=00:tw=30;42:ow=34;42:st=37;44:ex=01;32:*.7z=01;31:*.ace=01;31:*.alz=01;31:*.apk=01;31:*.arc=01;31:*.arj=01;31:*.bz=01;31:*.bz2=01;31:*.cab=01;31:*.cpio=01;31:*.crate=01;31:*.deb=01;31:*.drpm=01;31:*.dwm=01;31:*.dz=01;31:*.ear=01;31:*.egg=01;31:*.esd=01;31:*.gz=01;31:*.jar=01;31:*.lha=01;31:*.lrz=01;31:*.lz=01;31:*.lz4=01;31:*.lzh=01;31:*.lzma=01;31:*.lzo=01;31:*.pyz=01;31:*.rar=01;31:*.rpm=01;31:*.rz=01;31:*.sar=01;31:*.swm=01;31:*.t7z=01;31:*.tar=01;31:*.taz=01;31:*.tbz=01;31:*.tbz2=01;31:*.tgz=01;31:*.tlz=01;31:*.txz=01;31:*.tz=01;31:*.tzo=01;31:*.tzst=01;31:*.udeb=01;31:*.war=01;31:*.whl=01;31:*.wim=01;31:*.xz=01;31:*.z=01;31:*.zip=01;31:*.zoo=01;31:*.zst=01;31:*.avif=01;35:*.jpg=01;35:*.jpeg=01;35:*.mjpg=01;35:*.mjpeg=01;35:*.gif=01;35:*.bmp=01;35:*.pbm=01;35:*.pgm=01;35:*.ppm=01;35:*.tga=01;35:*.xbm=01;35:*.xpm=01;35:*.tif=01;35:*.tiff=01;35:*.png=01;35:*.svg=01;35:*.svgz=01;35:*.mng=01;35:*.pcx=01;35:*.mov=01;35:*.mpg=01;35:*.mpeg=01;35:*.m2v=01;35:*.mkv=01;35:*.webm=01;35:*.webp=01;35:*.ogm=01;35:*.mp4=01;35:*.m4v=01;35:*.mp4v=01;35:*.vob=01;35:*.qt=01;35:*.nuv=01;35:*.wmv=01;35:*.asf=01;35:*.rm=01;35:*.rmvb=01;35:*.flc=01;35:*.avi=01;35:*.fli=01;35:*.flv=01;35:*.gl=01;35:*.dl=01;35:*.xcf=01;35:*.xwd=01;35:*.yuv=01;35:*.cgm=01;35:*.emf=01;35:*.ogv=01;35:*.ogx=01;35:*.aac=01;36:*.au=01;36:*.flac=01;36:*.m4a=01;36:*.mid=01;36:*.midi=01;36:*.mka=01;36:*.mp3=01;36:*.mpc=01;36:*.ogg=01;36:*.ra=01;36:*.wav=01;36:*.oga=01;36:*.opus=01;36:*.spx=01;36:*.xspf=01;36:*~=00;90:*#=00;90:*.bak=00;90:*.crdownload=00;90:*.dpkg-dist=00;90:*.dpkg-new=00;90:*.dpkg-old=00;90:*.dpkg-tmp=00;90:*.old=00;90:*.orig=00;90:*.part=00;90:*.rej=00;90:*.rpmnew=00;90:*.rpmorig=00;90:*.rpmsave=00;90:*.swp=00;90:*.tmp=00;90:*.ucf-dist=00;90:*.ucf-new=00;90:*.ucf-old=00;90:",
            "MAIL": "/var/mail/devops",
            "PATH": "/home/devops/.devops/bin:/home/devops/bin:/usr/devops/bin:/usr/bin",
            "PWD": "/home/devops",
            "SHELL": "/bin/bash",
            "SHLVL": "1",
            "SSH_CLIENT": "10.89.0.13 60540 22",
            "SSH_CONNECTION": "10.89.0.13 60540 10.89.0.14 22",
            "SSH_TTY": "/dev/pts/0",
            "TERM": "xterm",
            "USER": "devops",
            "_": "/usr/bin/python3"
        },
        "ansible_eth0": {
            "active": true,
            "device": "eth0",
            "ipv4": {
                "address": "10.89.0.14",
                "broadcast": "10.89.0.255",
                "netmask": "255.255.255.0",
                "network": "10.89.0.0",
                "prefix": "24"
            },
            "ipv6": [
                {
                    "address": "fe80::1210:10ff:fe10:1011",
                    "prefix": "64",
                    "scope": "link"
                }
            ],
            "macaddress": "10:10:10:10:10:11",
            "mtu": 1500,
            "promisc": false,
            "speed": 10000,
            "type": "ether"
        },
        "ansible_fibre_channel_wwn": [],
        "ansible_fips": false,
        "ansible_flags": [
            "fpu",
            "vme",
            "de",
            "pse",
            "tsc",
            "msr",
            "pae",
            "mce",
            "cx8",
            "apic",
            "sep",
            "mtrr",
            "pge",
            "mca",
            "cmov",
            "pat",
            "pse36",
            "clflush",
            "mmx",
            "fxsr",
            "sse",
            "sse2",
            "ht",
            "syscall",
            "nx",
            "rdtscp",
            "lm",
            "constant_tsc",
            "rep_good",
            "nopl",
            "xtopology",
            "nonstop_tsc",
            "cpuid",
            "tsc_known_freq",
            "pni",
            "pclmulqdq",
            "ssse3",
            "cx16",
            "sse4_1",
            "sse4_2",
            "movbe",
            "popcnt",
            "aes",
            "rdrand",
            "hypervisor",
            "lahf_lm",
            "abm",
            "3dnowprefetch",
            "ibrs_enhanced",
            "fsgsbase",
            "bmi1",
            "bmi2",
            "invpcid",
            "rdseed",
            "adx",
            "clflushopt",
            "sha_ni",
            "arat",
            "md_clear",
            "flush_l1d",
            "arch_capabilities"
        ],
        "ansible_form_factor": "Other",
        "ansible_fqdn": "host1",
        "ansible_hostname": "host1",
        "ansible_hostnqn": "",
        "ansible_interfaces": [
            "lo",
            "eth0"
        ],
        "ansible_is_chroot": true,
        "ansible_iscsi_iqn": "",
        "ansible_kernel": "6.11.4-301.fc41.x86_64",
        "ansible_kernel_version": "#1 SMP PREEMPT_DYNAMIC Sun Oct 20 15:02:33 UTC 2024",
        "ansible_lo": {
            "active": true,
            "device": "lo",
            "ipv4": {
                "address": "127.0.0.1",
                "broadcast": "",
                "netmask": "255.0.0.0",
                "network": "127.0.0.0",
                "prefix": "8"
            },
            "ipv6": [
                {
                    "address": "::1",
                    "prefix": "128",
                    "scope": "host"
                }
            ],
            "mtu": 65536,
            "promisc": false,
            "type": "loopback"
        },
        "ansible_loadavg": {
            "15m": 0.0146484375,
            "1m": 0.17626953125,
            "5m": 0.04638671875
        },
        "ansible_local": {},
        "ansible_locally_reachable_ips": {
            "ipv4": [
                "10.89.0.14",
                "127.0.0.0/8",
                "127.0.0.1"
            ],
            "ipv6": [
                "::1",
                "fe80::1210:10ff:fe10:1011"
            ]
        },
        "ansible_lsb": {},
        "ansible_lvm": "N/A",
        "ansible_machine": "x86_64",
        "ansible_machine_id": "3f43282a3e234c309523d40481dcad85",
        "ansible_memfree_mb": 165,
        "ansible_memory_mb": {
            "nocache": {
                "free": 1740,
                "used": 2167
            },
            "real": {
                "free": 165,
                "total": 3907,
                "used": 3742
            },
            "swap": {
                "cached": 1,
                "free": 3138,
                "total": 3906,
                "used": 768
            }
        },
        "ansible_memtotal_mb": 3907,
        "ansible_mounts": [],
        "ansible_nodename": "host1",
        "ansible_os_family": "RedHat",
        "ansible_pkg_mgr": "dnf5",
        "ansible_proc_cmdline": {
            "BOOT_IMAGE": "(hd0,gpt2)/vmlinuz-6.11.4-301.fc41.x86_64",
            "quiet": true,
            "rhgb": true,
            "ro": true,
            "root": "UUID=cd46931f-f193-41b8-854e-a34bff8cc760",
            "rootflags": "subvol=root"
        },
        "ansible_processor": [
            "0",
            "GenuineIntel",
            "13th Gen Intel(R) Core(TM) i7-1370P",
            "1",
            "GenuineIntel",
            "13th Gen Intel(R) Core(TM) i7-1370P"
        ],
        "ansible_processor_cores": 2,
        "ansible_processor_count": 1,
        "ansible_processor_nproc": 2,
        "ansible_processor_threads_per_core": 1,
        "ansible_processor_vcpus": 2,
        "ansible_product_name": "VirtualBox",
        "ansible_product_serial": "NA",
        "ansible_product_uuid": "NA",
        "ansible_product_version": "1.2",
        "ansible_python": {
            "executable": "/usr/bin/python3",
            "has_sslcontext": true,
            "type": "cpython",
            "version": {
                "major": 3,
                "micro": 7,
                "minor": 13,
                "releaselevel": "final",
                "serial": 0
            },
            "version_info": [
                3,
                13,
                7,
                "final",
                0
            ]
        },
        "ansible_python_version": "3.13.7",
        "ansible_real_group_id": 1000,
        "ansible_real_user_id": 1000,
        "ansible_selinux": {
            "status": "disabled"
        },
        "ansible_selinux_python_present": true,
        "ansible_service_mgr": "systemd",
        "ansible_ssh_host_key_ecdsa_public": "AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBN8g9Ftw5UFwzlHuy+yJbhuVh8MHQXFMMnLYQHgpdET4m3i2O62+gqv3oOEfGUx/A7SaeUBmRWqE9QewHLeDCBM=",
        "ansible_ssh_host_key_ecdsa_public_keytype": "ecdsa-sha2-nistp256",
        "ansible_ssh_host_key_ed25519_public": "AAAAC3NzaC1lZDI1NTE5AAAAIPLBEGLxQR9dawu45j4Xp+uoKvs+RQpFTc7rm+yk/9ug",
        "ansible_ssh_host_key_ed25519_public_keytype": "ssh-ed25519",
        "ansible_ssh_host_key_rsa_public": "AAAAB3NzaC1yc2EAAAADAQABAAABgQDR8Cob0edqOBmF2BYbZ0EfsQXsMKRxjnClTlFYkIx/CSZ61pdg7bS4VAFD0JI7c65bo6gu/9AVF4XXsifXixxKrFLoeBQCZCt3YDam4A1aC+TaYMUXwT/sHBx2qtGXdDJT8obRjDQ9N0OpnrZCiA7wGBeS1eNKS4R+4FXOrm+mRp8eX6csNH+BFKvtUepW5ArVCKduYjC0JvNxo/4BZYaR65IpR8shXO87Hmln8jeAjtTIa8cuJYbh9cIEB+ztWP9IVqsUh7moZwpECEAi8SH+INufMkhXkvGQY6wYjtwjMBrMZEckuwwTueY2tKjoj87Q95jTB0I7982y3t4vrKn+ZlAEFNp2UfVDY2j+2lmj0TloFX8jpPQ9bCv3YAjrDbETccF0ZtJBrKzijBIatxh+uY21td6Fh6Qeoycfu/xEylF0Ghi2gneC6pzIkn1vOiKiNQB5gFypQrHh8WLlYj7i4EPcUpSO4l5WIlz2J5l/9jXNWKP0/KdYRSeM8vhNRPk=",
        "ansible_ssh_host_key_rsa_public_keytype": "ssh-rsa",
        "ansible_swapfree_mb": 3138,
        "ansible_swaptotal_mb": 3906,
        "ansible_system": "Linux",
        "ansible_system_capabilities": [
            ""
        ],
        "ansible_system_capabilities_enforced": "True",
        "ansible_system_vendor": "innotek GmbH",
        "ansible_systemd": {
            "features": "+PAM +AUDIT +SELINUX -APPARMOR +IMA +IPE +SMACK +SECCOMP -GCRYPT +GNUTLS +OPENSSL +ACL +BLKID +CURL +ELFUTILS +FIDO2 +IDN2 -IDN -IPTC +KMOD +LIBCRYPTSETUP +LIBCRYPTSETUP_PLUGINS +LIBFDISK +PCRE2 +PWQUALITY +P11KIT +QRENCODE +TPM2 +BZIP2 +LZ4 +XZ +ZLIB +ZSTD +BPF_FRAMEWORK +BTF +XKBCOMMON +UTMP +SYSVINIT +LIBARCHIVE",
            "version": 257
        },
        "ansible_uptime_seconds": 620910,
        "ansible_user_dir": "/home/devops",
        "ansible_user_gecos": "",
        "ansible_user_gid": 1000,
        "ansible_user_id": "devops",
        "ansible_user_shell": "/bin/bash",
        "ansible_user_uid": 1000,
        "ansible_userspace_architecture": "x86_64",
        "ansible_userspace_bits": "64",
        "ansible_virtualization_role": "guest",
        "ansible_virtualization_tech_guest": [
            "container",
            "oci",
            "virtualbox"
        ],
        "ansible_virtualization_tech_host": [],
        "ansible_virtualization_type": "oci",
        "gather_subset": [
            "all"
        ],
        "module_setup": true
    },
    "changed": false
}
```

---
### Custom Facts

`ansible.builtin.set_fact`

`/etc/ansible/facts.d/myhostfacts.fact`

```
{% for host in groups['app_servers'] %}
   {{ hostvars[host]['ansible_facts']['eth0']['ipv4']['address'] }}
{% endfor %}
```


