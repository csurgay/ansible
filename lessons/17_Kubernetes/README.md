# Section 17: Kubernetes with Ansible

### In this section the following subject will be covered:

1. Setup Kubernetes Toolset
1. Namespaces Creation
1. Pods Creation
1. Application Deployment
1. Configmap
1. Further Topics

---
## Setup Kubernetes Toolset

> [!NOTE]
> The lab has no Kubernetes cluster, so this section is a demonstration / outlook. The examples need a cluster and
> a kubeconfig (`~/.kube/config`) on the host that runs them.

```bash
ansible-galaxy collection install kubernetes.core   # already included in the "ansible" package
sudo dnf install -y python3-kubernetes              # Python client used by the modules
```

(`community.kubernetes` is the old, deprecated name of `kubernetes.core`.)

The `kubernetes.core.k8s` module talks to the Kubernetes **API**, not to the cluster nodes over SSH. Therefore the
Plays run on `localhost` (or one admin host with a kubeconfig), never with `hosts: all`.

---
## Namespaces Creation

```yaml
---
- name: Create Kubernetes namespace
  hosts: localhost
  gather_facts: false

  tasks:

    - name: Create k8s namespace
      kubernetes.core.k8s:
        api_version: v1
        kind: Namespace
        name: my-namespace   # lowercase letters, digits and '-' only
        state: present
```

#### Alternative Creation from Manifest

```yaml
- name: Create a Namespace from K8S YAML File
  kubernetes.core.k8s:
    state: present
    src: kube_manifests/mynamespace.yml
```

---
## Pods Creation

```yaml
---
- name: Kubernetes Pod Deployment
  hosts: localhost
  gather_facts: false
  vars:
    my_namespace: my-namespace

  tasks:

    - name: Create k8s Namespace
      kubernetes.core.k8s:
        api_version: v1
        kind: Namespace
        name: "{{ my_namespace }}"
        state: present

    - name: Create k8s Pod
      kubernetes.core.k8s:
        namespace: "{{ my_namespace }}"
        state: present
        definition:
          apiVersion: v1
          kind: Pod
          metadata:
            name: nginx
          spec:
            containers:
              - name: nginx
                image: nginx:latest
                ports:
                  - containerPort: 80
```

---
## Application Deployment

```yaml
- name: Application Deployment
  hosts: localhost
  gather_facts: false

  tasks:

    - name: Create a Deployment
      kubernetes.core.k8s:
        wait: true            # wait until the Pods are actually ready, not only accepted by the API
        wait_timeout: 120
        definition:
          apiVersion: apps/v1
          kind: Deployment
          metadata:
            name: myapp
            namespace: my-namespace
          spec:
            replicas: 3
            selector:
              matchLabels:
                app: myapp
            template:
              metadata:
                labels:
                  app: myapp
              spec:
                containers:
                  - name: myapp-container
                    image: nginx:latest
                    ports:
                      - containerPort: 80

    - name: Expose Deployment as a Service
      kubernetes.core.k8s:
        definition:
          apiVersion: v1
          kind: Service
          metadata:
            name: myapp-service
            namespace: my-namespace
          spec:
            selector:
              app: myapp
            ports:
              - protocol: TCP
                port: 80
                targetPort: 80
            type: ClusterIP   # LoadBalancer needs a cloud provider or MetalLB
```

---
## ConfigMap

```yaml
- name: Manage ConfigMaps and Secrets
  hosts: localhost
  gather_facts: false
  vars_files:
    - secrets.yml   # Vault-encrypted, defines myapp_password

  tasks:

    - name: Create ConfigMap
      kubernetes.core.k8s:
        definition:
          apiVersion: v1
          kind: ConfigMap
          metadata:
            name: app-configmap
            namespace: my-namespace
          data:
            config.json: |
              {
                "name": "John",
                "born": 1970
              }

    - name: Create Secret
      kubernetes.core.k8s:
        definition:
          apiVersion: v1
          kind: Secret
          metadata:
            name: myapp-secret
            namespace: my-namespace
          stringData:
            password: "{{ myapp_password }}"
      no_log: true
```

---
## Further Topics

- Configure Proxy Machine with Kube Config and Kubectl tools
- Deploy Kubernetes cluster with Ansible
- Deploy Ansible playbook to Kubernetes on a cloud provider
- Ansible for CI/CD in Kubernetes
- Integrating Ansible with a CI/CD GitOps tool
- Kubernetes upgrades with Ansible

