```
# Homelab Infrastructure as Code

This repo provisions a lightweight Proxmox LXC for Traefik and configures it with Ansible. The first service is a dedicated reverse proxy container running Traefik directly (no Docker).

## Structure

infra/
├── terraform/
│   ├── environments/
│   │   └── homelab/
│   │       ├── main.tf
│   │       ├── providers.tf
│   │       ├── variables.tf
│   │       ├── locals.tf
│   │       ├── outputs.tf
│   │       └── terraform.tfvars.example
│   └── modules/
│       └── lxc/
│           ├── main.tf
│           ├── variables.tf
│           └── outputs.tf
├── ansible/
│   ├── ansible.cfg
│   ├── inventory/
│   │   ├── hosts.ini
│   │   └── group_vars/
│   │       ├── all.yml
│   │       └── reverse_proxy.yml
│   ├── playbooks/
│   │   └── reverse-proxy.yml
│   └── roles/
│       └── traefik/
│           ├── defaults/main.yml
│           ├── handlers/main.yml
│           ├── tasks/main.yml
│           └── templates/traefik.service.j2
└── configs/
     └── traefik/
          ├── traefik.yml.j2
          └── dynamic.yml.j2

## Naming conventions

- Folders and playbooks: kebab-case
- Ansible group names and variables: snake_case
- Terraform module names: snake_case
- VMID scheme: 100-199 infra LXCs (reverse-proxy=110), 200-299 app LXCs, 300-399 storage/monitoring, 900-999 temp

## Workflow

1. Terraform (provision LXC)
    - cd terraform/environments/homelab
    - cp terraform.tfvars.example terraform.tfvars
    - Fill in Proxmox API values and any overrides
    - terraform init
    - terraform plan
    - terraform apply

2. Ansible (configure Traefik)
    - cd ansible
    - Update inventory/hosts.ini if needed
    - ansible-playbook playbooks/reverse-proxy.yml

## Defaults

- LXC: 1 vCPU, 512MB RAM, 8GB disk, 256MB swap
- IPv4: 192.168.1.110/24, gateway 192.168.1.1
- DNS: 192.168.1.90
- IPv6: auto (SLAAC)
- Template: ubuntu-24.04-standard_24.04-2_amd64.tar.zst
```