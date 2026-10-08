deploy-web-server
=================

Installs Apache httpd, deploys an `index.html` from a template, opens HTTP in firewalld and starts httpd.
A running nginx or lighttpd (from earlier lessons) is stopped, because it would block port 80.

Role Variables
--------------

`defaults/main.yml` (override them freely):

| Variable | Default |
|----------|---------|
| `web_title` | `Deployed by the deploy-web-server role` |
| `web_root` | `/var/www/html` |

`vars/main.yml` (internal): `web_package`, `web_service`, `web_conflicting_services`.

Example Playbook
----------------

    - hosts: myhosts
      become: true
      roles:
        - role: deploy-web-server
          vars:
            web_title: "Hello"

License
-------

MIT
