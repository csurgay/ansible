# Section 14. Roles

### In this section the following subjects will be covered:

1. Introduction to Roles
1. Roles Directory Structure
1. Roles Locatinos
1. Using Roles

---
## Introduction to Roles

Roles are shareable and reusable Ansible operations that follow a predefined directory structure of Ansible artifacts (task, vars, templates, handlers, tests, resource files, etc).

Roles can be called from your Playbooks, and can be given parameters specific to your application.

---
## Roles Directory Structure
```
roles/
    myrole1/              # this hierarchy represents a "role"
        tasks/            #
            main.yml      #  <-- tasks, can include other task files
        handlers/         #
            main.yml      #  <-- handlers file
        templates/        #  <-- files for template module
            ntp.conf.j2   #  <------- templates end in .j2
        files/            #
            mytext.txt    #  <-- files to copy
            myscript.sh   #  <-- script files for use with the script resource
        vars/             #
            main.yml      #  <-- variables for this role
        defaults/         #
            main.yml      #  <-- default variables for this role, low precedence
        meta/             #
            main.yml      #  <-- role dependencies
```

---
## Roles Locations

Roles can be placed in the `roles/` subdirctory relative to the Playbook file, or at the `roles_path` config key locations with it's default values:

- `~/.ansible/roles`
- `/usr/share/ansible/roles`
- `/etc/ansible/roles`

---
## Using Roles

### Play level Roles

There are two Play level Role reference, one with and one without providing parameter variables to the Role.
```
---
- name: Play level Roles
  hosts: all
  roles:
    - myrole1
    - role: myrole2
      vars:
        name: John
        born: 1970
```

### Including Roles

```
---
- name: Including Roles
  hosts: webservers
  tasks:
    - name: Print a message
      ansible.builtin.debug:
        msg: "this task runs before the example role"

    - name: Include the example role
      include_role:
        name: example
      vars:
         name: John
         born: 1970
      when: "ansible_fact['distribution'] == 'Fedora'"

    - name: Print a message
      ansible.builtin.debug:
        msg: "this task runs after the example role"
```

### Importing Roles

Similar as including a role but importing is pre-processed at Playbook parsing time, not execution time. Vars and Conditionals are copied into every task of the imported Role.

| Feature | import_role | include_role |
|---------|-------------|--------------|
| Processed | Static at parsing | Dynamic at runtime |
| Vars and Conditionals | Applied to all imported tasks | Applied only to include_role task |
| Within Loops | Not supported | Supported |
| Usage | Simple static inclusion | Dynamic, conditional and looped inclusion |


