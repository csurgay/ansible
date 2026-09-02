# Why learn Ansible - IaC - GitOps?

### In this section the following subjects will be covered:

1. Why Do We Automate?
1. Introduction to Ansible
1. Your First Playbook
1. Infrastructure as Code (IaC)
1. GitOps: Ansible + IaC + Git
1. Summary

---
## Why Do We Automate?

### The Problem with Manual Work

Traditionally, managing infrastructure and applications was done manually:
+ Manually installing packages on servers.
+ Editing configuration files by hand.
+ Deploying updates by copying files via scp or rsync.

### Challenges of manual processes:

|Issue|Why It's a Problem|
|-----|------------------|
|**Human error**|Mistakes happen, especially when steps are complex or repetitive|
|**Inconsistent environments**|"It works on my machine" because no two environments are configured the same way|
|**Slow deployments**|Manual setup can take hours or days|
|**Poor scalability**|Adding more servers increases manual workload linearly|
|**Difficult to audit**|Hard to track who did what and when|

### Benefits of Automation

|Benefit|Description|
|-------|-----------|
|**Consistency**|Every server or environment is configured exactly the same way|
|**Speed**|Automated processes run in minutes instead of hours|
|**Reliability**|Reduces human error by removing repetitive manual steps|
|**Scalability**|Easily scale infrastructure to hundreds or thousands of nodes|
|**Auditability**|Automation scripts provide a clear record of changes|
|**Agility**|Quickly adapt to changes in business needs|

### Real-World Example

Imagine setting up 10 web servers:

| | | |
|----------------|--------------|-----------|
| **Manually** | SSH into each server, install Nginx, configure it, open firewall rules | Takes hours and error-prone |
| **Automated** | Run one Ansible playbook | Ready in minutes, identical, and logged |

---
## Introduction to Ansible

Ansible is for automation and management of computers and systems across different platforms. It’s widely used by IT teams and has become a popular choice for large organizations that want to simplify and speed up their operations.

Supported by **Red Hat** and a strong open-source community, Ansible is great for **configuring systems, setting up infrastructure, and deploying applications**.

It can automate almost anything—from cloud and on-premise servers to IoT devices—making your IT environment **faster, more consistent, and more reliable**.

### Ansible is an open-source automation tool that helps you

+ Provision servers
+ Configure infrastructure
+ Deploy applications
+ Manage complex IT workflows

### Advantages of Ansible

* **Free and open-source**, supported by a large and active community.
* **Proven and reliable**, trusted by IT professionals for many years.
* **Easy to learn and use**, with no need for advanced programming skills.
* **Simple to set up**, since it doesn’t require any extra agents.
* **Flexible and modular**, with powerful features that grow with your experience.
* **Well-documented**, with official guides and plenty of helpful community resources online.

### Key Characteristics

+ **Agentless** → No special software needed on managed nodes, just SSH and Python.
+ **Declarative** → You describe the desired state, and Ansible makes it happen.
+ **Idempotent** → Running the same playbook multiple times won't break things.

### Ansible automation

Ansible works using two types of machines: a **control node** and **managed nodes**. The control node is the computer where Ansible is installed. From there, it connects to the managed nodes and sends them commands and instructions.

The pieces of code that Ansible runs on managed nodes are called **modules**. Each module is triggered by a **task**, and a list of tasks forms a **playbook**. In a playbook, you describe what the system should look like or what actions should happen.

All managed machines are listed in a simple **inventory file**, which can group them into different categories.

Ansible uses **YAML**, an easy-to-read language, to define playbooks, so you can understand and write them from the very beginning.

One big advantage of Ansible is that it **doesn’t need any agent software** installed on the managed machines—making setup and use very straightforward.

In most cases, all you need is a **terminal** to run commands and a **text editor** to write your configuration files.

### Ansible Core Concepts

|Concept|Description|
|------------|------------------------------------------|
| **Control node** | A host where Ansible (and Python) is running playbooks |
| **Managed hosts** | Servers that Ansible manages, configures, provisions; need no Ansible but Python |
| **Group** | A set of hosts that share something in common |
| **Inventory** | A list of servers or devices you manage, written in a simple text file |
| **Module** | A small piece of (python) code that Ansible runs on the remote machines to perform specific actions |
| **Playbook** | A YAML file containing one or more Plays |
| **Play** | A YAML list of tasks, describing step-by-step how a system should be configured |
| **Role** | A structured way to organize playbooks, variables, and files for reuse and sharing |
| **Task** | A single action (e.g., "Install Nginx", "Copy a file") |
| **Handler** | A special Task executed only if notified by previous Tasks |
| **Idempotence** | Ensures running tasks repeatedly doesn’t cause unintended changes |
| **YAML** | A simple, human-friendly text format that Ansible uses to define playbooks and configuration files |

### How Ansible Works

1. You write a playbook describing the desired configuration.
2. Ansible connects via SSH to each target machine.
2. Tasks are executed using modules (like package, service, copy).
2. System state is enforced and logged.

---
## Your First Playbook

Here’s a simple playbook to install and start Nginx:

#### your-first-playbook.yml
```yaml
---
- name: Install and configure web server
  hosts: host1, host2
  become: yes
  # run with --ask-become-pass (-K)

  tasks:

    - name: Install Nginx
      ansible.builtin.dnf:
        name: nginx
        state: present

    - name: Start and enable Nginx
      ansible.builtin.systemd:
        name: nginx
        state: started
        enabled: true
```

Where 

#### inventory.ini
```yaml
host1
host2
```

#### Run it:
```bash
ansible-playbook -i inventory.ini -K your-first-playbook.yml
```

#### Testing
```bash
for i in {1..2}; do ssh host$i curl -s localhost | grep "/title"; done
```

---
## Infrastructure as Code (IaC)

### What is IaC?

Infrastructure as Code (IaC) is the practice of managing and provisioning infrastructure through code, rather than manually through GUIs or CLI commands.

Examples of things you can manage with IaC:

+ Servers (physical or virtual)
+ Cloud resources (AWS, Azure, GCP)
+ Networks and firewalls
+ Load balancers
+ Databases

### Benefits

| Version Control | Store infrastructure definitions in Git like application code |
| Collaboration | Teams can review changes via pull requests before applying them |
| Reproducibility | Build identical environments across dev, test, and production |
| Disaster Recovery | Quickly rebuild environments from code if something fails |
| Documentation | The code itself becomes the documentation |

### IaC Workflow Example

1. Developer writes a playbook defining a new web server setup.
1. Playbook is committed to GitHub/GitLab.
1. CI/CD pipeline runs the playbook automatically.
1. Infrastructure is deployed consistently across all environments.

---
## GitOps: Ansible + IaC + Git

+ Infrastructure is defined as YAML playbooks.
+ Configurations are automated and repeatable.
+ All changes are version-controlled.
+ The process can be integrated with CI/CD pipelines.

### Use Case Example

Server provisioning	Deploy 50 cloud VMs on AWS in minutes
Configuration management	Ensure every server has the correct users, packages, and services
Application deployment	Zero-downtime rolling updates of a web application
Security compliance	Enforce password policies, firewall rules, and auditing settings
Disaster recovery	Quickly rebuild production from code

### BitOps benefits

|     |          |
|-----|----------|
| **Single truth** | Master blueprint of your entire infrastructure in Playbooks |
| **Speed** | Deploy in minutes instead of hours or days |
| **Consistency** | Identical environments every time |
| **Reuse** | Write once, use 1000 times across planes, datacenters |
| **Auditability** | Track who changed what and when via Git |
| **Scalability** | Manage 10 or 10,000 servers the same way |
| **Collaboration** | Infrastructure changes reviewed like software code |
| **Resilience** | Recover from failures by re-applying playbooks |
| **Version control** | Earlier versions and branches at your fingertip |

<img src="https://csurgay.com/ansible/gitops.png" width="600">

### Visual Workflow

```mermaid
flowchart TD;
  id1[Write Playbook] --> id2[(Commit to Git)] --> id3((CI/CD Pipeline))  --> id4[[Ansible Applies Changes]] --> id5([Infrastructure Updated]);
```

### Recommended Tools

|      |        |
|------|--------|
| Ansible | Core automation tool |
| Git | Version control for playbooks |
| Podman/Docker | For local test environments |
| vim, VS Code | Editing YAML files with syntax highlighting |

---
## Summary

Automation with Ansible and IaC transforms the way we manage infrastructure:

+ Manual work → Code-driven processe
+ Slow, error-prone changes → Fast, reliable deployments
+ Hidden tribal knowledge → Transparent, version-controlled playbooks

The result is faster development cycles, scalable infrastructure, and reduced risk.

> [!TIP]
> Key takeaway: Treat infrastructure like code, automate everything possible,
> and use Ansible to enforce consistency and reliability across your environments.


