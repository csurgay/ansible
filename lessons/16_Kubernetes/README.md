# Section 16: Kubernetes with Ansible

### In this section the following subject will be covered:

1. Setup Kubernetes Toolset
1. Namespaces Creation
1. Pods Creation
1. Application Deployment
1. Configmap
1. Further Topics

---
## Setup Kubernetes Toolset

```bash
ansible-galaxy collection install kubernetes.core
ansible-galaxy collection install community.kubernetes
ansible-galaxy collection install cloud.common

sudo dnf install python3-pip
pip install kubernetes
```

---
## Namespaces Creation

```yaml
---
- name: Create Kubernetes namespace
  hosts: all

  tasks:

    - name: Create k8s namespace
      kubernetes.core.k8s:
        api_version: v1
        kind: Namespace
        name: "MyNamespace"
        state: present
```

#### Alternative Creation from Manifest

```yaml
- name: Create a Namespace from K8S YAML File
  kubernetes.core.k8s:
    state: present
    src: /kube_manifests/mynamespace.yml
```

---
## Pods Creation

```yaml
---
- name: Kubernetes Pod Deployment
  hosts: all
  vars:
    my_namespace: "MyNamespece"

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
  hosts: proxy_servers

  tasks:

    - name: Create a Deployment
      kubernetes.core.k8s:
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
            type: LoadBalancer
```

---
## ConfigMap

```yaml
- name: Manage ConfigMaps
  hosts: proxy_servers

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
            password: mypassword
```

---
## Further Topics

- Configure Proxy Machine with Kube Config and Kubectl tools
- Deploy Kubernetes cluster with Ansible
- Deploy Ansible playbook to Kubernetes on a cloud provider
- Ansible for CI/CD in Kubernetes
- Integrating Ansible with a CI/CD GitOps tool
- Kubernetes upgrades with Ansible

