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

## Workflow: Traefik Reverse Proxy Setup

### 1. Provision Infrastructure with Terraform
1. Navigate to the homelab environment: `cd terraform/environments/homelab`
2. Create your variables file: `cp terraform.tfvars.example terraform.tfvars`
3. Edit `terraform.tfvars` with your Proxmox credentials and the local Proxmox template ID (`lxc_template_file_id`).
4. Initialize and apply: 
   ```bash
   terraform init
   terraform apply
   ```

### 2. Configure Traefik with Ansible
1. Navigate to the Ansible directory: `cd ansible`
2. Verify `inventory/hosts.ini` has the correct LXC IP (default `192.168.1.110`).
3. Verify your Traefik services and domain (`homelab118.home`) are configured in `inventory/group_vars/reverse_proxy.yml`.
4. Run the configuration playbook:
   ```bash
   ansible-playbook playbooks/reverse-proxy.yml
   ```
   *This playbook installs Traefik directly on the system (no Docker), sets up local DNS/hosts entries, and generates a self-signed wildcard TLS certificate.*

### 3. Trust the Self-Signed Certificate Locally (Chrome/System)
Since we are using a self-signed wildcard certificate for our homelab domain (`homelab118.home`), we must explicitly trust it on our local machine (laptop/desktop) to remove browser security warnings.

Run the following commands on your **local machine** (assuming Ubuntu/Debian):

```bash
# 1. Pull the newly generated cert to your local machine
scp root@192.168.1.110:/etc/traefik/certs/traefik.crt ./traefik.crt

# 2. Clean out old conflicting certs from Chrome's database (ignore errors if not present)
certutil -d sql:$HOME/.pki/nssdb -D -n "traefik" || true
certutil -d sql:$HOME/.pki/nssdb -D -n "caddy" || true

# 3. Import the new correct cert into Chrome's trust store
certutil -d sql:$HOME/.pki/nssdb -A -t "C,," -n "traefik" -i ./traefik.crt

# 4. Add to OS System Trust (Ubuntu/Debian) securely
sudo cp ./traefik.crt /usr/local/share/ca-certificates/traefik.crt
sudo update-ca-certificates
```

**Important:** Fully close and reopen Chrome for the trusted certificate to take effect.

> **Regenerating Certs:** If you change the domain name or need to regenerate the cert later, first delete them from the LXC (`ssh root@192.168.1.110 "rm -f /etc/traefik/certs/traefik.*"`), rerun the Ansible playbook, and repeat the local trust steps above.

## Defaults

- LXC: 1 vCPU, 512MB RAM, 8GB disk, 256MB swap
- IPv4: 192.168.1.110/24, gateway 192.168.1.1
- DNS: 192.168.1.90
- IPv6: auto (SLAAC)
- Template: ubuntu-24.04-standard_24.04-2_amd64.tar.zst
```