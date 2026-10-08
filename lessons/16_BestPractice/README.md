# Section 16: Ansible Best Practice

### In this section the following subjects will be covered:

1. General Principles
1. Recommended Project Structure
1. Inventory Management
1. Playbooks and Task Design
1. Debug Practices
1. Variable Management
1. Module Usage
1. Roles
1. Execution and Deployment
1. Security Practices
1. Additional Notes
1. References

---
## General Principles

- Write variable files and inventories in **YAML** (or INI) rather than JSON.  
  - YAML is easier to read, comment and maintain than JSON. 
- Keep **consistent indentation** and spacing.  
  - Consistent indentation ensures files parse correctly and improves readability. 
- Write **clear comments** describing tasks.  
  - Comments clarify **why** tasks exist. 
- Follow **consistent naming** for tasks, variables, roles, and files.  
  - Naming conventions help you locate and understand tasks, variables, and roles. 
- Store projects in **version control** (e.g., Git).  
  - Version control tracks changes and simplifies collaboration. 
- Use **ansible-lint** for linting and **molecule** for testing roles.  
  - `ansible-lint playbook.yml` catches style problems, deprecated syntax and common bugs before they run. 
- Use **tags** to organize and run specific tasks.  
  - Tags help run only specific parts of a playbook.
- Use **fully qualified module names** (FQCN): `ansible.builtin.copy`, `ansible.posix.firewalld`.
  - FQCN avoids ambiguity between collections and is checked by ansible-lint.
- **Start simple** and expand gradually.
  - Starting simple reduces complexity and prevents errors.

---
## Recommended Project Structure

```
inventory/
  production
  staging
  test

group_vars/
  web.yml
  db.yml

host_vars/
  web01.yml
  db01.yml

library/
module_utils/
filter_plugins/

site.yml
web.yml
db.yml

roles/
  webserver/
    tasks/main.yml
    handlers/main.yml
    templates/web.conf.j2
    files/setup.sh
    vars/main.yml
    defaults/main.yml
    meta/main.yml

  database/
    tasks/main.yml
    handlers/main.yml
```

To create a new role skeleton:

```bash
ansible-galaxy role init <role_name>
```

- Separate inventories per environment prevent mistakes. 
- Group and host variable directories organize configuration and reduce duplication. 
- Custom modules and plugins are stored in dedicated folders. 
- `site.yml` orchestrates smaller playbooks for modularity. 
- Roles include tasks, handlers, templates, files, variables, defaults, and metadata for reuse. 
- Using `ansible-galaxy role init` reduces setup errors.

---
## Inventory Management

Inventories define which hosts Ansible manages. Proper inventory practices ensure tasks run correctly.

- Group hosts logically (by function, environment, or location).  
- Keep separate inventories for each environment (`production`, `staging`).  
- Use **dynamic inventories** for cloud or changing environments.  
- Use **group_by** to create runtime groups.

Example:

```yaml
- name: Group by OS
  hosts: all
  tasks:
    - name: Create OS-based groups
      ansible.builtin.group_by:
        key: os_{{ ansible_facts['distribution'] }}
```

Conditional plays:

```yaml
- name: Fedora specific configuration
  hosts: os_Fedora
  tasks:
    - name: Print a message
      ansible.builtin.debug:
        msg: "Fedora specific configuration"
```

- Logical grouping simplifies targeting tasks and ensures correct execution. 
- Separate inventory files avoid mistakes in multiple environments. 
- Dynamic inventories help manage changing hosts in cloud environments. 
- `group_by` dynamically assigns hosts to groups at runtime. 
- Conditional plays allow running tasks only on specific hosts, improving efficiency and reducing risk.

---
## Playbooks and Task Design

- Always **declare the desired state**.  
- Put **each argument on a separate line**.  
- Group related tasks with **blocks**.  
- Use **handlers** for triggered actions.  
- Use a top-level playbook (`site.yml`) to orchestrate smaller playbooks.

Example task:

```yaml
- name: Create application user
  ansible.builtin.user:
    name: "{{ app_user }}"
    state: present
    uid: 1100
    generate_ssh_key: true
  become: true
```

Example block:

```yaml
- name: Install and configure web server
  when: ansible_facts['os_family'] == 'RedHat'
  tags: web
  become: true
  block:
    - name: Install nginx
      ansible.builtin.dnf:
        name: nginx
        state: present

    - name: Deploy configuration
      ansible.builtin.template:
        src: templates/nginx.conf.j2
        dest: /etc/nginx/conf.d/mysite.conf
        mode: '0644'
      notify: Restart nginx
```

Handler example:

```yaml
handlers:
  - name: Restart nginx
    ansible.builtin.service:
      name: nginx
      state: restarted
```

- Declaring states ensures tasks behave as expected. 
- Separate lines for arguments improve readability. 
- Blocks group related tasks, simplifying management and error handling. 
- Handlers run only when changes occur, improving efficiency. 
- Top-level playbooks provide orchestration and modularity.

---
## Debug Practices

Register the result of a task that may fail, let the Play continue, and print the details only when it failed.
(Without `ignore_errors` or a `block`/`rescue`, a failed task stops the Play for that host, so a later `debug`
task would never run.)

```yaml
- name: Install EDB server packages
  ansible.builtin.dnf:
    name: "{{ edb_server_packages }}"
    state: present
  register: result_install
  ignore_errors: true

- name: Show the details of the failure
  ansible.builtin.debug:
    var: result_install
  when: result_install is failed

- name: Stop here with a clear message
  ansible.builtin.fail:
    msg: "Package installation failed, see above"
  when: result_install is failed
```

Other debugging aids: `-v`/`-vvv`, `--check --diff`, `--start-at-task "<name>"`, `--step`,
and the `ansible.builtin.assert` module to check assumptions early.

---
## Variable Management

- Define **defaults** in `roles/<role>/defaults/main.yml`.  
- Use `group_vars` and `host_vars` directories.  
- Prefix variable names with role or context names to avoid conflicts.

Example:

```yaml
webserver_port: 8080
database_port: 5432
```
- Quote strings that start with `{{` or contain `:` (`msg: "Port: {{ port }}"`), and quote file modes (`mode: '0644'`).
- Keep variable logic simple.
- Defaults provide fallback values. 
- Group and host variables organize configuration per host or group. 
- Prefixing names prevents collisions. 
- Proper quoting ensures correct interpretation. 
- Simple variables reduce complexity and improve readability.

---
## Module Usage

- Place custom modules in `./library`.  
- Prefer **idempotent modules** over `shell` or `command`.  
- Always specify **state**.  
- Combine similar actions using lists.

Example:

```yaml
- name: Install packages
  ansible.builtin.dnf:
    name:
      - curl
      - unzip
      - git
    state: present
```

Prefer `state: present` over `state: latest`: `latest` upgrades packages whenever a new version appears, so the
same Playbook may do different things on different days. Upgrade deliberately, in a separate run.

- Custom modules in the library are automatically available. 
- Idempotent modules ensure safe repeatable operations. 
- Explicit states clarify intended behavior. 
- Using lists avoids repetitive code and improves readability.

---
## Roles

Roles group tasks, handlers, and variables into reusable components.

- Roles should perform one clear function.
  - If multiple functions are mixed in one role, reusability suffers
- Follow **Ansible Galaxy** structure.  
  - Galaxy standards improve readability. 
- Keep roles **focused** and loosely coupled.  
  - Loosely coupled roles are reusable. 
- Use **import_role** or **include_role** for execution control.  
  - Importing roles controls execution order. 
- Validate and store external roles locally.
  - Storing validated roles locally avoids dependency issues.

---
## Execution and Deployment

- Test in **staging** before production.  
  - Testing in staging prevents production mistakes. 
- Limit execution using `--limit` or `--tags`.  
  - Limiting execution targets the desired hosts or tasks. 
- Preview execution with `--list-tasks`, `--list-hosts`, `--check`, `--diff`.  
  - Previewing shows what would happen. 
- Resume partial runs with `--start-at-task "<task name>"`.  
  - Provides for faster debugging
- Use `serial` for **rolling updates**.  
  - Rolling updates prevent downtime by updating hosts in batches. 
- Explore [execution strategies](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_strategies.html).
  - Execution strategies optimize task performance in large deployments.


---
## Security Practices

- Use **Ansible Vault** or external secrets managers.  
  - Vault encrypts sensitive information. 
- Limit `become` usage to necessary tasks.  
  - Limiting privilege escalation reduces risk. 
- Apply **RBAC** and governance controls.  
  - RBAC gives fine-grained access control. 
- Scan for vulnerabilities regularly.  
  - Regular scans identify issues. 
- Log and monitor executions centrally.
  - Logging and monitoring provide audit trails and help troubleshoot.
- Use **`no_log`** to prevent logging sensitive data.

---
## Additional Notes

- Ensure **idempotency** across all tasks.  
  - Idempotent tasks are safe to run multiple times. 
- Use **role dependencies** carefully.  
  - Careful role dependency management keeps roles modular. 
- Integrate **dynamic inventories** for hybrid environments.  
  - Dynamic inventories simplify hybrid deployments. 
- Keep provisioning (creating VMs, cloud resources) and configuration in separate Playbooks or roles.
  - They change at a different pace and are often run by different teams.

---
## References

- [Ansible Inventory Guide](https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html)  
- [Ansible Playbooks Guide](https://docs.ansible.com/ansible/latest/playbook_guide/index.html)  
- [Ansible Modules Reference](https://docs.ansible.com/ansible/latest/collections/index_module.html)  
- [Molecule Testing Framework](https://molecule.readthedocs.io/)  
- [Ansible Galaxy](https://galaxy.ansible.com/)  

