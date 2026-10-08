# Webserver testing

### In this lesson the following subjects are covered

1. Pass a variable on the command line with `-e`
1. Check input with `assert`
1. Stop services that may or may not exist (`failed_when: false`)
1. Choose values with `set_fact` + `when`
1. Deploy content with a Jinja2 `template`
1. Test a webserver with `uri`, on the host itself and from the Control Node

---
## Switch between two webservers

The Playbook installs **either** `httpd` (Apache) **or** `nginx` on all Managed Hosts, depending on the
`webserver` variable given on the command line:

```bash
ansible-playbook -e webserver=nginx webserver.yml
ansible-playbook -e webserver=httpd webserver.yml
```

(`./run.sh httpd` does the same.) All of them listen on port 80, so the Playbook first **stops the others** (if they are installed at all; `lighttpd`
may run on host2 after [19_Git](../../19_Git/README.md)) and then starts the selected one.
`['httpd', 'nginx', 'lighttpd'] | difference([webserver])` is a Jinja2 filter expression that removes the selected
webserver from the list.

### Validate the input with assert

```yaml
    - name: Testing input parameter webserver
      ansible.builtin.assert:
        that: webserver in ['httpd', 'nginx']
        fail_msg: "Run with -e webserver=httpd or -e webserver=nginx"
```

Try running the Playbook without `-e`, or with `-e webserver=lighttpd`.

### Stop services that may not exist

`systemctl stop` fails for a service that is not installed. `failed_when: false` tells Ansible to never
treat this task as failed — cleaner than `ignore_errors: true`, which still prints red errors.

### set_fact + when

The document root differs: `/var/www/html/` for httpd and `/usr/share/nginx/html/` for nginx.
Two `set_fact` tasks with opposite `when` conditions set `weblocation`, only one of them runs per host.

### The template

#### index.html.j2
```
Hi there from {{ webserver }} at {{ inventory_hostname }}!
```

`ansible.builtin.template` renders the file on the Control Node, substituting the variables, and copies the
result to the Managed Host.

---
## Running the Playbook

#### webserver.yml
```yaml
---
- name: Play 1. Install and run httpd or nginx with webcontent template
  hosts: myhosts
  gather_facts: false
  become: true

  tasks:

    - name: Testing input parameter webserver
      ansible.builtin.assert:
        that: webserver in ['httpd', 'nginx']
        fail_msg: "Run with -e webserver=httpd or -e webserver=nginx"

    - name: Stop the other webserver, it would also use port 80
      ansible.builtin.systemd:
        name: "{{ item }}"
        state: stopped
      loop: "{{ ['httpd', 'nginx', 'lighttpd'] | difference([webserver]) }}"
      failed_when: false

    - name: Install webserver httpd or nginx
      ansible.builtin.package:
        name: "{{ webserver }}"
        state: present

    - name: Start and enable the selected webserver
      ansible.builtin.systemd:
        name: "{{ webserver }}"
        state: started
        enabled: true

    - name: Set location for webcontent (httpd)
      ansible.builtin.set_fact:
        weblocation: "/var/www/html/"
      when: webserver == "httpd"

    - name: Set location for webcontent (nginx)
      ansible.builtin.set_fact:
        weblocation: "/usr/share/nginx/html/"
      when: webserver == "nginx"

    - name: Create webcontent
      ansible.builtin.template:
        src: index.html.j2
        dest: "{{ weblocation }}index.html"
        owner: root
        group: root
        mode: '0644'

    - name: Open HTTP service in public zone
      ansible.posix.firewalld:
        zone: public
        service: http
        permanent: true
        immediate: true
        state: enabled

    - name: Check webcontent 200 status code from the host itself
      ansible.builtin.uri:
        url: http://localhost
        return_content: true
      register: container_response

    - name: Debug container response
      ansible.builtin.debug:
        var: container_response.content

- name: Play 2. Tests from the Control Node
  hosts: localhost
  gather_facts: false
  become: false

  tasks:

    - name: Check webcontent 200 status code from the Control Node
      ansible.builtin.uri:
        url: "http://{{ item }}"
        return_content: true
      loop: "{{ groups['myhosts'] }}"
      register: localhost_response

    - name: Print the pages
      ansible.builtin.debug:
        msg: "From localhost: {{ item.content }}"
      loop: "{{ localhost_response.results }}"
      loop_control:
        label: "{{ item.item }}"
```

```bash
ansible-playbook -e webserver=nginx webserver.yml
curl http://host2            # from the Control Node
```

From the builder VM the hosts are also reachable on the published ports: `curl http://localhost:8081` (host1),
`8082` (host2), `8083` (host3) — these are the `web_port` values in `host_inventory`.

**Try this:** switch all hosts to `httpd` and back to `nginx`. Which tasks report `changed` on a second run
with the same webserver?
