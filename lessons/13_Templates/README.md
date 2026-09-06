# Section 13: Templates

### In this section the following subjects will be covered:

1. Templates
2. Jinja2
3. Examples

---
## Templates

Ansible templating lets you automatically create text-based files (like configuration files) that can change depending on variables and system Facts. The main goal is to make managing configurations easier and more consistent across multiple systems.

If you have several similar environments with slightly different settings, you don’t need to create or edit each configuration file by hand. Instead, you can create one template and let Ansible fill in the details for each system using variables and Facts. This avoids duplicate files and reduces mistakes.

When updates are needed, you only change the template once, and Ansible will generate new files for all systems.

---
## Jinja2

By default, Ansible uses the Jinja2 templating engine to create dynamic content.

Jinja2 is a powerful Python-based template engine that’s also used in web frameworks like Flask and Django. It allows you to mix plain text with special syntax to include variables, conditions, and loops in your files.

The main syntax is:

- `{{ }}` for variables or expressions
- `{% %}` for logic statements (like loops or conditions)
- `{# #}` for comments

#### Variable
```yaml
My favourite color is {{ favourite_color }}
```

#### If Statement
```yaml
{% if age > 18 %}
You are an adult and can vote at {{ voting_center }}
{% else %}
Sorry, you are a minor and can’t vote yet.
{% endif %}
```

#### Loop
```yaml
Here’s a list of fruits:
{% for fruit in fruits %}
{{ fruit }}
{% endfor %}
```

Templating happens before tasks are sent to the managed host, so you don’t need any extra software installed there. It also keeps network traffic small since the final files are generated locally.

Jinja2 also comes with filters and tests to modify data. Ansible adds extra ones to make it easier to work with variables and external data sources.

---
## Examples

### Example 1: Basic Template

This template example shows how variables, conditionals, and loops combine to generate a complete configuration file.

#### test.conf.j2
```yaml
My favourite color is {{ favourite_color }}

{% if age > 18 %}
You are an adult, and you can vote in the voting center: {{ voting_center }}
{% else %}
Sorry, you are a minor and you can’t vote yet.
{% endif %}

A list of fruits:
{% for fruit in fruits %}
 - {{ fruit }}
{% endfor %}
```

#### playbook.yml
```yaml
- name: Playbook to test templates
  hosts: all
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
      template:
        src: templates/test.conf.j2
        dest: /tmp/test.conf
```

#### Result
```yaml
My favourite color is blue

You are an adult, and you can vote in the voting center: ab456-g

A list of fruits:
 - banana
 - apple
 - mango
 - pear
```

### Example 2: Nginx Config

Now let’s use a template to create an Nginx web server configuration file.

#### nginx.conf.j2
```yaml
server {
       listen {{ web_server_port }};
       listen [::]:{{ web_server_port }};
       root {{ nginx_custom_directory }};
       index index.html;
       location / {
               try_files $uri $uri/ =404;
       }
}
```

#### playbook.yml
```yaml
- name: Provision nginx web server
  hosts: all
  gather_facts: yes
  become: yes
  vars:
    nginx_version: 1.18.0-0ubuntu1.4
    nginx_custom_directory: /home/ubuntu/nginx
    web_server_port: 80

  tasks:
    - name: Update and upgrade apt
      apt:
        update_cache: yes
        cache_valid_time: 3600
        upgrade: yes

    - name: Install Nginx to specific version
      apt:
        name: "nginx={{ nginx_version }}"
        state: present

    - name: Copy Nginx configuration from template
      template:
        src: templates/nginx.conf.j2
        dest: /etc/nginx/sites-available/default

    - name: Enable Nginx config
      file:
        src: /etc/nginx/sites-available/default
        dest: /etc/nginx/sites-enabled/default
        state: link

    - name: Create Nginx directory
      file:
        path: "{{ nginx_custom_directory }}"
        state: directory

    - name: Copy index.html
      copy:
        src: files/index.html
        dest: "{{ nginx_custom_directory }}/index.html"

    - name: Restart Nginx
      service:
        name: nginx
        state: restarted
```

#### test index.html
```html
<html>
  <head>
    <title>Hello from Nginx</title>
  </head>
  <body>
    <h1>This is our test web server</h1>
    <p>This Nginx web server was deployed by Ansible.</p>
  </body>
</html>
```

Run the playbook, then log into your server to check the file `/etc/nginx/sites-available/default`. 

You’ll see the configuration file generated from your template — confirming that the templating and deployment worked perfectly.


