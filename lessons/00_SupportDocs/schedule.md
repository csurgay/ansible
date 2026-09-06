## Schedule of the week

| Day | Session | Topics |
|-----|---------|--------|
| 1 | 1	| Why automate, what is Ansible, architecture, infrastructure as code, installing Ansible and ssh keys, ad-hoc commands |
|	| 2	| Inventories (static), hosts, hostgroups, nested groups, host ranges, host patterns, Ansible config, first playbooks, multiple plays |
| 2 | 3	| YAML syntax, finding modules, variables and facts, variable precedence, inventory host and group variables, vars directories |
|	| 4	| Secrets with Ansible Vault, create and edit encrypted files, secrets in playbooks, managing passwords, using ansible_facts, magic variables |
| 3 |	5 |	Task control: conditionals, iteration with loops, multiple conditions, combining loops and conditions, handlers, error handling |
| |	6	| Files and templates with Jinja2, file modules, SELinux context changes, copying and editing files, synchronizing, using Jijna2, Jinja2 loops and conditionals |
| 4	| 7	| Importing in large playbooks, Roles, Role structure, using and creating roles, system Roles, dependencies, best practices |
|	| 8	| Ansible Galaxy, browsing Roles, Galaxy command line, Deploying with Galaxy, requirements file, reuse |
| 5	| 9	| Debug module, check mode, ad-hoc testing, Linux admin tasks with Ansible, user management, package management, services management, storage management |
| |	10	| Further topics, Summary and Q&A session|


---
## Day 1 Session 1 – Introduction to Automation and Ansible

- Understand why to automating Linux administration tasks with Ansible
- Learn what Ansible is, how Ansible works
- Install and configure Ansible on a Control Node
- Purpose of Ansible ad-hoc commands and the Ansible cli-toolset
- Run single automation tasks with Ansible ad-hoc commands
- Use ansible-doc to learn about modules you can use

## Day 1 Session 2 - Inventories

- Create a list (inventory) of the systems you manage, write a simple playbook, and run it to automate tasks
- Learn how Ansible inventories work and how to manage a simple static inventory file
- Inventory Hosts, Hostgroups, Nested groups, Host ranges, Host patterns
- Find out where Ansible configuration files are located and how Ansible decides which one to use
- Edit configuration files to change default settings
- Write and run a basic playbook with the ansible-playbook command
- Write a playbook with several plays, including privilege escalation

## Day 2 Session 3 - YAML, modules, variables

- YAML vs JSON syntax and semantics
- Static inventory files
- How to find modules
- Use variables and facts in playbooks to make them easier to manage and reuse
- Create and use variables that apply to specific hosts, groups, plays, or globally
- How Ansible decides which variable takes priority (Variable precedence)
- Use Ansible facts to get system information from managed hosts
- Create your own custom facts

## Day 2 Session 4 - Vault, Magic variables

- Protect sensitive variables with Ansible Vault
- Run playbooks that use encrypted variable files
- Create and edit vault secret files
- Magic variables for hosts related Ansible management data

## Day 3 Session 5 - Task control

- Manage how tasks run and how errors are handled in playbooks
- Loops to repeat tasks efficiently
- Conditions to decide when tasks should run
- Create tasks that only run when another task changes something on a host
- Control what happens if a task fails, and decide when a task should be marked as failed

## Day 3 Session - 6 Templates

- Copy files to Managed Hosts
- Fetch files from Managed Hosts
- Change textfile content
- Create and Delete files and directories on Managed Hosts
- Control permissions and ownership of files
- Deploy files that are automatically customized with Jinja2 templates
- Download files to Managed Hosts
- Jinja2 Loops and Conditionals

## Day 4 Session 7 - Complex Playbooks

– Handling large or complex Playbooks
- Organize and simplify complex automation projects
- Use advanced host patterns to choose exactly which systems to target
- Difference between include_task and import_task
- Split large playbooks into smaller pieces by including or importing other files
- Include/import either always or only when certain conditions are true

## Day 4 Session 8 - Roles

- Use roles to make your playbooks easier to write and reuse
- What a roles are, how they are organized, and how to use them in Playbooks
- Use Red Hat Enterprise Linux System Roles to perform common system tasks.
- Create your own role inside a project and run it in a Playbook
- Download and use roles from Ansible Galaxy or other sources like Git repositories

## Day 5 Session 9 – Troubleshooting

- Find and fix problems with playbooks or managed hosts
- Debug general playbook issues and fix them
- Investigate and solve errors that happen on managed systems during playbook runs
- Use Ansible to handle everyday Linux administration jobs automatically

## Day 5 Session 10 - Further topics, Summary, Q&A

