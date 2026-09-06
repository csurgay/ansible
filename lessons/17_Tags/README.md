# Section 17: Tags

#### In this section the following subjects will be covered:

1. Understanding Ansible Tags
1. How to use Tags
1. List all Tags
1. Multiple Tags
1. Skip Tags
1. `always` and `never`
1. Advanced Tag usage
1. Best Practice
1. Examples

---
## Understanding Ansible tags?

Ansible tags let you control exactly which Tasks, Roles, or Plays run in a Playbook. You add tags in the YAML Playbook file and assign them to a Task or a Role. When you run `ansible-playbook` with the `--tags` option, only the tasks with those tags will run, and everything else will be skipped.

This is useful when you don’t want to run the entire Playbook but only certain parts. It helps prevent unwanted changes or disruptions in your systems.

Why not just use conditionals? Conditionals only run a Task if a specific condition is true. Tags give you more control because you can run the task directly from the command line, no matter the conditions.

#### Benefits of Using Tags

|            |              |
|------------|--------------|
| Easier debugging | If something is not working, you can add a tag to the Task you want to test. Running only that tag helps you find the problem without executing the whole Playbook |
| Flexible execution | Tags allow you to skip Tasks that might cause issues during a particular run |
| Reuse Tasks | You can run the same Tasks or Roles in different situations by using tags, making your playbooks more efficient |

---
## Usage of Tags

You can add tags to Tasks, Roles, or Plays in your Playbook.

#### Adding a Tag to a Task

In this example, we add tags to Tasks that install and start the Apache webserver:

```yaml
---
- name: Apache Setup
  hosts: test
  tasks:
    - name: Install Apache
      apt:
        name: apache2
        state: present
      tags: install_apache

    - name: Start Apache Service
      service:
        name: apache2
        state: started
      tags: start_service
```

#### To run only the Install Apache Task, use:

```bash
ansible-playbook playbook.yml --tags "install_apache"
```

#### To run only the Start Apache Task, use:

```bash
ansible-playbook playbook.yml --tags "start_service"
```

#### Adding a Tag to a Role

Tags work the same way for Roles:

```yaml
---
- name: Role Playbook
  hosts: test
  roles:
    - role: standard_linux_package
      tags: standard_package

    - role: tomcat_app
      tags: tomcat
```

#### To run only the Tomcat Role and skip the standard Linux package Role, use:
```bash
ansible-playbook playbook.yml --tags "tomcat"
```

---
## List all Tags

When your Playbook has many tTsks or Roles, it can be hard to know which tags are used where. Listing all tags helps you see which Tasks, Roles, or Plays can be run or skipped individually.

You can do this using the `--list-tags˙` option with the `ansible-playbook` command.

#### Example Playbook:
```yaml
---
- name: Apache Setup
  hosts: test
  tasks:
    - name: Install Apache
      apt:
        name: apache2
        state: present
      tags:
        - install

    - name: Start Apache Service
      service:
        name: apache2
        state: started
      tags:
        - start

    - name: Configure Apache
      template:
        src: apache.conf.j2
        dest: /etc/apache2/apache2.conf
      tags:
        - configure
```

#### To list all the Tags in this Playbook, run:
```bash
ansible-playbook apache-playbook.yml --list-tags
```

#### The output will show all the Tasks and their Tags, for example:
```
playbook: apache_playbook.yml

  play #1 (all): Apache    TAGS: []
    task #1: Install Apache    TAGS: [install]
    task #2: Start Apache Service    TAGS: [start]
    task #3: Configure Apache    TAGS: [configure]
```

This makes it easy to know which tags you can run or skip when executing your Playbook.

---
## Multiple Tags

You can assign more than one tag to Tasks, Roles, or Plays in a Playbook. This makes your Playbook more flexible and gives you better control over what runs.

Multiple tags are useful when Tasks belong to different groups. For example, you might want some Tasks to be part of a `webserver` group and others part of a `database` group, while still keeping tags for specific actions like install, start, or configure.

#### Example: Grouping Tasks with Multiple Tags
```yaml
---
- name: MyWebApp Setup
  hosts: test
  tasks:
    - name: Install Apache
      apt:
        name: apache2
        state: present
      tags:
        - install
        - webserver

    - name: Install MySQL
      apt:
        name: mysql-server
        state: present
      tags:
        - install
        - database

    - name: Configure Apache
      template:
        src: apache.conf.j2
        dest: /etc/apache2/apache2.conf
      tags:
        - configure
        - webserver

    - name: Configure MySQL
      template:
        src: my.cnf.j2
        dest: /etc/mysql/my.cnf
      tags:
        - configure
        - database

    - name: Start Apache Service
      service:
        name: apache2
        state: started
      tags:
        - start
        - webserver

    - name: Start MySQL Service
      service:
        name: mysql
        state: started
      tags:
        - start
        - database
```

#### Run all install Tasks:
```bash
ansible-playbook myapp.yml --tags "install"
```

#### Run only webserver Tasks:
```bash
ansible-playbook myapp.yml --tags "webserver"
```

#### Run only database Tasks:
```bash
ansible-playbook myapp.yml --tags "database"
```

#### You can also skip certain Tags when running a Playbook:
```bash
ansible-playbook example_playbook.yml --skip-tags "configure"
```

This allows you to run only the Tasks you need without affecting others.

---
## Skip Tags

Sometimes you may want to skip certain Tasks while letting the rest of your Playbook run. By using the `--skip-tags` option, you can omit specific Tasks during execution.

#### Example: Skipping a Task During Deployment

Suppose you want to apply configuration changes without restarting the service:
```yaml
---
- name: Update Configuration
  hosts: all
  tasks:
    - name: Apply new configuration
      template:
        src: new_config.j2
        dest: /etc/myapp/config.conf
      tags: update_config

    - name: Restart myapp service
      service:
        name: myapp
        state: restarted
      tags: restart_service
```

#### Run this command to skip restarting the service:
```bash
ansible-playbook update_config.yml --skip-tags "restart_service"
```

#### Example: Skipping Tasks in Specific Environments

Tags can also help when deploying to different environments (dev, QA, UAT, prod). You can skip certain Tasks in non-development environments:
```yaml
---
- name: App Deployment
  hosts: all
  tasks:
    - name: Install dependencies
      apt:
        name: "{{ item }}"
        state: present
      loop:
        - git
        - curl
      tags: install_dependencies

    - name: Deploy application code
      git:
        repo: 'https://github.com/me/app.git'
        dest: /var/www/myapp
      tags: deploy_code

    - name: Configure application
      template:
        src: app_config.j2
        dest: /etc/myapp/config.conf
      tags:
        - configure_app
        - skip_in_production

    - name: Restart application service
      service:
        name: app
        state: restarted
      tags:
        - restart_service
        - skip_in_production

    - name: Run database migrations
      command: /usr/local/bin/migrate_db.sh
      tags:
        - migrate_db
        - skip_in_production
```

#### Inventory file example:
```yaml
[dev]
dev.app.com

[qa]
qa.app.com

[uat]
uat.app.com

[production]
prod.app.com
```

#### To run the Playbook only in non-dev environments while skipping certain Tasks:
```bash
ansible-playbook manage_app.yml --limit production --skip-tags "skip_in_production"
ansible-playbook manage_app.yml --limit qa --skip-tags "skip_in_production"
ansible-playbook manage_app.yml --limit uat --skip-tags "skip_in_production"
```

The `--skip-tags` flag gives you flexibility to control exactly which Tasks run in each environment.

---
## `always` and `never`

Ansible has two special tags that help keep your playbooks consistent and safe:

`always`: This tag ensures a Task runs every time, no matter what other tags are used on the command line. Use it for critical checks, environment setup, or cleanup Tasks that must always run.

`never`: This tag ensures a Task never runs, regardless of other tags. It is useful for deprecated Tasks or for temporarily disabling Tasks during testing or debugging.

#### Example: Always Run Cleanup Tasks

This Playbook deploys the application and config, but always deletes temporary files, no matter which tag is used:
```yaml
---
- name: App Deployment
  hosts: all
  tasks:
    - name: Deploy application
      git:
        repo: 'https://github.com/app/myapp.git'
        dest: /var/www/myapp
      tags: deploy_code

    - name: Configure application
      template:
        src: app_config.j2
        dest: /etc/myapp/config.conf
      tags: configure_app

    - name: Cleanup temporary files
      file:
        path: /tmp/myapp_temp
        state: absent
      tags: always
```

#### Example: Never Run Deprecated Tasks

If a Task is deprecated, you can use the `never` tag to prevent it from running, even if someone uses its tag:
```yaml
---
- name: Update Database Schema
  hosts: db_servers
  tasks:
    - name: Backup database
      command: /usr/local/bin/db_backup.sh
      tags: db_backup

    - name: Update database schema (deprecated)
      command: /usr/local/bin/db_update.sh
      tags:
        - db_update
        - never

    - name: Reboot database server
      reboot:
      tags: reboot_db
```

#### Example: Using Always and Never Together

You can use `always` and `never` in the same Playbook without conflicts:
```yaml
---
- name: Deploy Application
  hosts: all
  tasks:
    - name: Validate environment
      command: /usr/local/bin/validate_env.sh
      tags: always

    - name: Deploy application
      git:
        repo: 'https://github.com/app/myapp.git'
        dest: /var/www/myapp
      tags: deploy_app

    - name: Deprecated deployment step
      command: /usr/local/bin/deprecated_deploy.sh
      tags:
        - deprecated
        - never

    - name: Cleanup environment
      command: /usr/local/bin/cleanup_env.sh
      tags: always
```

This ensures that important Tasks always run, and deprecated Tasks never run, giving you more control and stability in your Playbook.

---
## Advanced tag usage

Ansible tags can be used in more advanced ways with variables, Facts, Roles, and imports to make your Playbooks more flexible and efficient.

#### Using Tags with Variables

You can assign tag values through variables so that all your tag management is centralized instead of scattered across the Playbook.
```yaml
---
- name: Playbook with Tags and Variables
  hosts: all
  vars:
    install_tag: "install_apache"

  tasks:
    - name: Install Apache
      apt:
        name: apache2
        state: present
      tags: "{{ install_tag }}"
```

You can also trigger variables only when their associated tag is used. For example, we can set web_server_port to apply only when the webserver tag is called, and db_server_port only when the dbserver tag is used:
```yaml
- hosts: all
  vars:
    web_server_port: 80
    db_server_port: 5432

  tasks:
    - name: Install web server
      tags: webserver
      yum:
        name: httpd
        state: present

    - name: Start web server
      tags: webserver
      service:
        name: httpd
        state: started

    - name: Configure web server port
      tags: webserver
      lineinfile:
        path: /etc/httpd/conf/httpd.conf
        regexp: '^Listen '
        line: "Listen {{ web_server_port }}"
        notify: restart webserver

    - name: Install database server
      tags: dbserver
      yum:
        name: postgresql-server
        state: present

    - name: Start database server
      tags: dbserver
      service:
        name: postgresql
        state: started

    - name: Configure database server port
      tags: dbserver
      lineinfile:
        path: /var/lib/pgsql/data/postgresql.conf
        regexp: '^port = '
        line: "port = {{ db_server_port }}"
        notify: restart dbserver

  handlers:
    - name: restart webserver
      service:
        name: httpd
        state: restarted

    - name: restart dbserver
      service:
        name: postgresql
        state: restarted
```

#### Using Tags with Facts

Ansible Facts are system details collected from Managed Hosts. By default, Facts are gathered at the start of every Playbook, but this can slow down execution. You can use tags to gather Facts only when needed.
```yaml
---
- name: Gather facts with tags
  hosts: all
  gather_facts: false
  tasks:
    - name: Gather facts
      setup:
      tags: gather_facts

    - name: Install Apache on Debian
      apt:
        name: apache2
        state: present
      when: ansible_facts['os_family'] == "Debian"
      tags:
        - install_apache

    - name: Install Apache on CentOS
      yum:
        name: httpd
        state: present
      when: ansible_facts['os_family'] == "RedHat"
      tags:
        - install_apache
```

#### You can also conditionally gather Facts for specific environments:
```yaml
---
- name: Gather facts in non-production
  hosts: all
  gather_facts: false
  tasks:
    - name: Gather facts in non-prod
      setup:
      tags: gather_facts_non_prod
      when: env != "production"

    - name: Deploy application
      git:
        repo: 'https://github.com/example/myapp.git'
        dest: /var/www/myapp
      tags: deploy_app
```

#### Inventory example:
```ini
[development]
dev.company.com env=development

[production]
prod.company.com env=production
```

#### Command to run only on the dev environment:
```bash
ansible-playbook deployment_playbook.yml --tags "gather_facts_non_prod,deploy_app"
```

#### Using Tags with Roles and Imports

You can also tag Roles and imported Tasks to control exactly which parts of a Playbook are executed.
```yaml
---
- name: Deploy Application
  hosts: all
  roles:
    - { role: common, tags: ['common'] }
    - { role: webserver, tags: ['webserver'] }
    - { role: database, tags: ['database'] }

  tasks:
    - name: Import additional common tasks
      import_tasks: standard_tasks.yml
      tags: standard_tasks

    - name: Import additional webserver tasks
      import_tasks: webserver_tasks.yml
      tags: webserver_tasks

    - name: Import additional database tasks
      import_tasks: database_tasks.yml
      tags: database_tasks
```

#### Example of imported standard Tasks:
```yaml
---
- name: Install additional common utilities
  apt:
    name: "{{ item }}"
    state: present
  loop:
    - htop
    - tree

- name: Configure timezone
  timezone:
    name: 'Etc/UTC'

- name: Set up NTP service
  apt:
    name: ntp
    state: present

- name: Start and enable NTP service
  service:
    name: ntp
    state: started
    enabled: yes

- name: Update system packages
  apt:
    upgrade: dist
```

#### To run a webserver deployment with its additional Tasks, use:
```bash
ansible-playbook deploy_application.yml --tags "webserver,standard_tasks,webserver_tasks"
```

---
## Best Practice

| Best Practice Category | Guidelines | Good Tag Example | Bad Tag Example |
|------------------------|------------|-----------------|----------------|
| **Consistency** | - Follow naming conventions for clarity.<br>- Group related Tasks under one tag. | `install_apache`, `configure_db` | `task1`, `setup` |
| **Documentation** | - Add comments explaining unclear Tasks.<br>- Maintain a tag reference document.<br>- Follow team guidelines for tag usage. | `# Tag used to install web server`<br>`deploy_app` | No comments or scattered tag definitions |
| **Avoid Overusing Tags** | - Limit tags per Task (2-3 max).<br>- Only tag Tasks that can run independently.<br>- Avoid duplicate or redundant tags.<br>- Periodically review tags. | `install_web, webserver` | `install_web, setup_web, deploy_web` |
| **Reusability** | - Use tags to group Tasks that might be reused in multiple scenarios.<br>- Make tags descriptive enough to indicate purpose. | `database_setup`, `webserver_tasks` | `misc_task`, `do_stuff` |
| **Control Execution** | - Use tags to run or skip Tasks selectively without affecting other Tasks.<br>- Combine with `--tags` or `--skip-tags` for precise control. | `ansible-playbook site.yml --tags "webserver"` | Running the full Playbook every time without tags |

---
## Examples

Ansible tags let you run specific Tasks, Roles, or Plays without executing the entire Playbook. Here are some practical use cases.

#### Example 1: Database Maintenance

Use tags to manage database tasks independently:
```yaml
- name: Database Maintenance
  hosts: db_servers
  tasks:
    - name: Backup database
      command: /usr/local/bin/db_backup.sh
      tags: 
        - backup

    - name: Update database schema
      command: /usr/local/bin/db_update.sh
      tags: 
        - update

    - name: Restart database service
      service:
        name: postgresql
        state: restarted
      tags: 
        - restart
```

#### Commands:
```bash
ansible-playbook db_maintenance.yml --tags "backup"
ansible-playbook db_maintenance.yml --tags "update"
ansible-playbook db_maintenance.yml --tags "restart"
```

#### Example 2: Application Deployment to Different Environments

Control deployments to dev, staging, or production using tags:
```yaml
- name: App Deployment
  hosts: all
  tasks:
    - name: Install dependencies
      apt:
        name: "{{ item }}"
        state: present
      loop:
        - python3-pip
        - git
      tags: 
        - install
        - dev
        - staging
        - prod

    - name: Deploy app in dev
      git:
        repo: 'https://github.com/app/dev_app.git'
        dest: /var/www/myapp
      tags: 
        - deploy
        - dev

    - name: Deploy app in staging
      git:
        repo: 'https://github.com/app/stage_app.git'
        dest: /var/www/myapp
      tags: 
        - deploy
        - staging

    - name: Deploy app in prod
      git:
        repo: 'https://github.com/app/prod_app.git'
        dest: /var/www/myapp
      tags: 
        - deploy
        - prod

    - name: Start app service
      service:
        name: myapp
        state: started
      tags: 
        - dev
        - staging
        - prod
```

#### Commands:
```bash
ansible-playbook app.yml --tags "install,deploy,dev"
ansible-playbook app.yml --tags "install,deploy,staging"
ansible-playbook app.yml --tags "install,deploy,prod"
```

#### Example 3: Rolling Updates in High-Availability Environments

Tags help control rolling updates to minimize downtime:
```yaml
- name: Rolling Update for Web Servers
  hosts: web_servers
  serial: 1
  tasks:
    - name: Take server out of load balancer
      command: /usr/local/bin/remove_from_lb.sh
      tags: 
        - lb_remove

    - name: Update application code
      git:
        repo: 'https://github.com/app/myapp.git'
        dest: /var/www/myapp
      tags: 
        - update_code

    - name: Restart web server
      service:
        name: apache2
        state: restarted
      tags: 
        - restart

    - name: Add server back to load balancer
      command: /usr/local/bin/add_to_lb.sh
      tags: 
        - lb_add
```

#### Commands:
```bash
ansible-playbook rolling_update.yml --tags "lb_remove"
ansible-playbook rolling_update.yml --tags "update_code"
ansible-playbook rolling_update.yml --tags "restart"
```

#### Example 4: Managing Multiple Services

Use tags to manage web servers, application servers, and databases in one playbook:
```yaml
- name: Managing Multi-Service
  hosts: all
  tasks:
    - name: Install web server
      apt:
        name: apache2
        state: present
      tags: 
        - install
        - webserver

    - name: Install app server
      apt:
        name: tomcat
        state: present
      tags: 
        - install
        - appserver

    - name: Install db server
      apt:
        name: postgresql
        state: present
      tags: 
        - install
        - dbserver

    - name: Configure web server
      template:
        src: apache.conf.j2
        dest: /etc/apache2/apache2.conf
      tags: 
        - configure
        - webserver

    - name: Configure app server
      template:
        src: tomcat.conf.j2
        dest: /etc/tomcat/tomcat.conf
      tags: 
        - configure
        - appserver

    - name: Configure db server
      template:
        src: postgresql.conf.j2
        dest: /etc/postgresql/postgresql.conf
      tags: 
        - configure
        - dbserver

    - name: Start web server service
      service:
        name: apache2
        state: started
      tags: 
        - start
        - webserver

    - name: Start app server service
      service:
        name: tomcat
        state: started
      tags: 
        - start
        - appserver

    - name: Start db server service
      service:
        name: postgresql
        state: started
      tags: 
        - start
        - dbserver
```

#### Commands:
```bash
ansible-playbook multi_service.yml --tags "install,configure,webserver"
ansible-playbook multi_service.yml --tags "start,appserver"
ansible-playbook multi_service.yml --tags "install,configure,start,dbserver"
```



