# Section 13: Templates

### In this section the following subjects will be covered:

1. Templates
1. Jinja2
1. Exercises

---
## Templates

Ansible templating lets you automatically create text-based files (like configuration files) that can change depending on variables and system Facts. The main goal is to make managing configurations easier and more consistent across multiple systems.

If you have several similar environments with slightly different settings, you don’t need to create or edit each configuration file by hand. Instead, you can create one template and let Ansible fill in the details for each system using variables and Facts. This avoids duplicate files and reduces mistakes.

When updates are needed, you only change the template once, and Ansible will generate new files for all systems.

---
## Jinja2

Ansible uses the Jinja2 templating engine to create dynamic content.

Jinja2 is a powerful Python-based template engine that’s also used in web frameworks like Flask. It allows you to mix plain text with special syntax to include variables, conditions, and loops in your files.

The main syntax is:

- `{{ }}` for variables or expressions
- `{% %}` for logic statements (like loops or conditions)
- `{# #}` for comments

#### Variable
```jinja
My favourite color is {{ favourite_color }}
```

#### If Statement
```jinja
{% if age | int > 18 %}
You are an adult and can vote at {{ voting_center }}
{% else %}
Sorry, you are a minor and can’t vote yet.
{% endif %}
```

#### Loop
```jinja
Here’s a list of fruits:
{% for fruit in fruits %}
{{ fruit }}
{% endfor %}
```

#### Filters
```jinja
{{ name | upper }}                     {# JOHN #}
{{ port | default(80) }}               {# 80 if port is undefined #}
{{ servers | join(', ') }}             {# a, b, c #}
{{ users | map(attribute='name') | list }}
```

Templating happens on the **Control Node**: the `template` module renders the file there and copies the result to the Managed Host, so nothing extra is needed on the Managed Hosts. Templates can use all variables and facts of the host they are rendered for.

Jinja2 comes with many filters and tests to modify data, and Ansible adds extra ones (e.g. `password_hash`, `regex_search`, `to_nice_yaml`).

> [!TIP]
> Put `# {{ ansible_managed }}` into the first line of templated config files: it renders as a comment telling
> everybody that the file is managed by Ansible and manual edits will be overwritten.

---
## Exercises

Each subdirectory is a small project with its own `ansible.cfg` and `host_inventory`.

### 00-basics: variables, conditions, loops

#### templates/test.conf.j2
```jinja
My favourite color is {{ favourite_color }}

{% if age | int > 18 %}
You are an adult, and you can vote in the voting center: {{ voting_center }}
{% else %}
Sorry, you are a minor and you can't vote yet.
{% endif %}

A list of fruits:
{% for fruit in fruits %}
 - {{ fruit }}
{% endfor %}
{# This is a Jinja2 comment, it does not appear in the result #}
Generated for {{ inventory_hostname }} ({{ ansible_facts['distribution'] }} {{ ansible_facts['distribution_version'] }})
```

#### playbook.yml
```yaml
---
- name: Playbook to test templates
  hosts: host1
  gather_facts: true
  vars:
    favourite_color: blue
    age: 21
    voting_center: ab456-g
    fruits:
      - banana
      - apple
      - mango
      - pear

  tasks:
    - name: Template test
      ansible.builtin.template:
        src: templates/test.conf.j2
        dest: /tmp/test.conf
        mode: '0644'

    - name: Read the result back
      ansible.builtin.command: cat /tmp/test.conf
      register: result_cat
      changed_when: false

    - name: Print the result
      ansible.builtin.debug:
        var: result_cat.stdout_lines
```

```bash
cd 00-basics
ansible-playbook playbook.yml
```

Change `age` to 16 with `-e age=16` and run again. Why does the `{# ... #}` line not appear in the result?
(Values given with `-e key=value` are always **strings**, that is why the template converts `age` with the `int` filter.)

### 01-hostdata: facts of all hosts in one file

`hostdata.j2` loops over `groups['all']` and reads the facts of **every** host through `hostvars`, so each Managed
Host gets a file listing the IP, MAC, interface, date and FQDN of all hosts.

```bash
cd 01-hostdata
ansible-playbook hostdata.yml
```

### 02-report: lineinfile vs template

`report.yml` fills the placeholders of `report.txt` one by one with four `lineinfile` tasks.
`report_template.yml` produces the same result with **one** `template` task and `report.txt.j2`.
Compare the two: which one is easier to read and to extend? When is `lineinfile` still the right tool?
(Hint: when you own only one line of a file that someone else manages.)

If you own **several** consecutive lines of such a file, use `ansible.builtin.blockinfile` instead of
`lineinfile`: it wraps the block in marker comments and updates (not duplicates) it on the next run.

```yaml
- name: Manage the proxy section of app.ini
  ansible.builtin.blockinfile:
    path: /etc/myapp/app.ini
    block: |
      [proxy]
      host={{ proxy_host }}
      port={{ proxy_port }}
```

The file then contains `# BEGIN ANSIBLE MANAGED BLOCK` ... `# END ANSIBLE MANAGED BLOCK` around the lines.
A multi-line `line:` in `lineinfile` would never match a single line of the file, so it would be inserted
again on every run.

```bash
cd 02-report
ansible-playbook report.yml && ansible host1 -m command -a "cat /tmp/report.txt"
ansible-playbook report_template.yml && ansible host1 -m command -a "cat /tmp/report.txt"
```

### 03-storage: a Markdown report built with Jinja2

`storage.yml` collects mount point facts and builds a Markdown table with a Jinja2 loop, including
whitespace control (`{%-`), `set` and `round`. Run it on a VM (see `RUN_THIS_ON_VM_NOT_CONTAINER`): containers
report no mounts.

### 04-nginx-site: a website from templates

A second nginx website on port 8080 on every Managed Host: the nginx config and the `index.html` both come
from templates, and a handler reloads nginx only when the config changed.

#### templates/training-site.conf.j2
```jinja
# {{ ansible_managed }}
server {
    listen       {{ site_port }};
    server_name  {{ inventory_hostname }};
    root         {{ site_root }};
    index        index.html;

    location / {
        try_files $uri $uri/ =404;
    }
}
```

#### templates/index.html.j2
```jinja
<html>
  <head>
    <title>{{ site_title }}</title>
  </head>
  <body>
    <h1>{{ site_title }}</h1>
    <p>This page of {{ inventory_hostname }} ({{ ansible_facts['default_ipv4']['address'] }}) was deployed by Ansible.</p>
    <ul>
{% for host in groups['myhosts'] %}
      <li><a href="http://{{ host }}:{{ site_port }}/">{{ host }}</a>{% if host == inventory_hostname %} (this host){% endif %}</li>
{% endfor %}
    </ul>
  </body>
</html>
```

#### nginx-site.yml
```yaml
---
- name: Provision an extra nginx website from templates
  hosts: myhosts
  gather_facts: true
  become: true
  vars:
    site_port: 8080
    site_root: /srv/training-site
    site_title: Hello from the Ansible Bootcamp

  tasks:
    - name: Install nginx
      ansible.builtin.dnf:
        name: nginx
        state: present

    - name: Create the web root
      ansible.builtin.file:
        path: "{{ site_root }}"
        state: directory
        mode: '0755'

    - name: Deploy index.html from template
      ansible.builtin.template:
        src: templates/index.html.j2
        dest: "{{ site_root }}/index.html"
        mode: '0644'

    - name: Deploy the nginx site config from template
      ansible.builtin.template:
        src: templates/training-site.conf.j2
        dest: /etc/nginx/conf.d/training-site.conf
        mode: '0644'
      notify: Reload nginx

    - name: Open the site port in the firewall
      ansible.posix.firewalld:
        port: "{{ site_port }}/tcp"
        permanent: true
        immediate: true
        state: enabled

    - name: Start and enable nginx
      ansible.builtin.systemd:
        name: nginx
        state: started
        enabled: true

  handlers:
    - name: Reload nginx
      ansible.builtin.systemd:
        name: nginx
        state: reloaded

- name: Test the sites from the Control Node
  hosts: localhost
  gather_facts: false
  become: false
  vars:
    site_port: 8080

  tasks:
    - name: Request every site
      ansible.builtin.uri:
        url: "http://{{ item }}:{{ site_port }}/"
        return_content: true
      loop: "{{ groups['myhosts'] }}"
      register: result_sites

    - name: Print the titles
      ansible.builtin.debug:
        msg: "{{ item.item }}: {{ item.content | regex_search('<title>(.*)</title>', '\\1') | first }}"
      loop: "{{ result_sites.results }}"
      loop_control:
        label: "{{ item.item }}"
```

```bash
cd 04-nginx-site
ansible-playbook nginx-site.yml
curl http://host1:8080/
```

Run it again with `-e "site_title='New title'"`: which tasks change, and does the handler run? Why not?
(Hint: which template contains the title?)
