# Homelab Infrastructure as Code

This repository manages a modular Homelab environment on Proxmox using **Terraform** for LXC provisioning and **Ansible** for configuration management. It is designed around modular, category-based deployments to maintain a small state "blast radius" and clear separation of concerns.

## Current Services

- **Networking**: Dedicated reverse proxy container running Traefik (VMID 110).
- **Databases**: Unified database server running PostgreSQL 16 and MongoDB 4.4 (VMID 300).
- **Applications**: Plex Media Server running in a Privileged LXC with Intel QuickSync GPU Passthrough and UFW firewall (VMID 202).

## Repository Structure

```text
infra/
├── terraform/
│   ├── environments/
│   │   └── homelab/
│   │       ├── common.auto.tfvars         # Centralized common variables (API keys, SSH paths)
│   │       ├── applications/              # Plex Media Server
│   │       │   ├── main.tf
│   │       │   ├── common.auto.tfvars -> ../common.auto.tfvars
│   │       │   └── terraform.tfvars       # App-specific overrides
│   │       ├── databases/                 # Postgres & MongoDB
│   │       │   ├── main.tf
│   │       │   ├── common.auto.tfvars -> ../common.auto.tfvars
│   │       │   └── terraform.tfvars
│   │       └── networking/                # Traefik Reverse Proxy
│   │           ├── main.tf
│   │           ├── common.auto.tfvars -> ../common.auto.tfvars
│   │           └── terraform.tfvars
│   └── modules/
│       └── lxc/                           # Reusable Proxmox LXC Module
├── ansible/
│   ├── ansible.cfg
│   ├── inventory/
│   │   ├── hosts.ini                      # Defines [postgres], [applications], [reverse_proxy]
│   │   └── group_vars/                    # Configs like DB passwords, listening ports
│   ├── playbooks/
│   │   ├── applications.yml               # Runs Plex role
│   │   ├── databases.yml                  # Runs Postgres & MongoDB roles
│   │   └── reverse-proxy.yml              # Runs Traefik role
│   └── roles/
│       ├── mongodb/                       # Installs MongoDB 4.4 (Non-AVX compatible)
│       ├── plex/                          # Installs Plex & UFW, configures QuickSync groups
│       ├── postgres/                      # Installs Postgres 16, configures SCRAM-SHA-256
│       └── traefik/                       # Installs Traefik natively
└── README.md
```

## Terraform Architecture: Centralized Variables

To prevent duplicating sensitive API tokens and Proxmox credentials across multiple Terraform states, we use a centralized `common.auto.tfvars` file located at `terraform/environments/homelab/common.auto.tfvars`.

Each subdirectory (`applications/`, `databases/`, `networking/`) contains a **symbolic link** to this central file. 
When you run `terraform apply` inside any of the directories, Terraform automatically loads the global variables from the symlink, while allowing you to define local IP/CPU overrides in the directory's specific `terraform.tfvars`.

## Deployment Workflow

### 1. Provision Infrastructure (Terraform)
1. Navigate to the specific category you want to deploy (e.g., Databases):
   ```bash
   cd terraform/environments/homelab/databases
   ```
2. Ensure the `common.auto.tfvars` symlink exists and your local `terraform.tfvars` is configured.
3. Apply the infrastructure:
   ```bash
   terraform init
   terraform apply
   ```
*Note: If deploying the **Plex** LXC, you must manually add the Intel QuickSync device mappings to `/etc/pve/lxc/202.conf` on the Proxmox host after Terraform finishes.*

### 2. Configure Services (Ansible)
1. Navigate to the Ansible directory: `cd ansible`
2. Update the credentials and variables in `inventory/group_vars/` (e.g., `databases.yml`).
3. Run the corresponding playbook:
   ```bash
   ansible-playbook playbooks/databases.yml -i inventory/hosts.ini
   ```

---

## Bootstrap: SSH Agent Forwarding (Local -> LXC1 -> LXC2)

This workflow keeps the private key only on your local machine. LXC1 (`infra-mgmt`) stores the public key for Terraform to inject into new LXCs (LXC2), and Ansible uses SSH agent forwarding to authenticate without private keys on LXC1 or LXC2.

### 1. Local machine: create key + enable agent forwarding
Generate a dedicated ED25519 key for the homelab if it does not exist:
```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_proxmox -C "homelab-proxmox"
```

Add a wildcard SSH config so all `192.168.1.*` hosts use the key and forward the agent:
```sshconfig
Host 192.168.1.*
   User root
   IdentityFile ~/.ssh/id_ed25519_proxmox
   IdentitiesOnly yes
   ForwardAgent yes
```

Start the agent and load the key:
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_proxmox
```

### 2. Local machine: authorize access to LXC1
Authorize your public key on LXC1 so you can log in:
```bash
ssh-copy-id -i ~/.ssh/id_ed25519_proxmox.pub root@192.168.1.150
```

### 3. Local machine -> LXC1: copy the public key for Terraform
Copy only the public key to LXC1 so Terraform can read it:
```bash
scp ~/.ssh/id_ed25519_proxmox.pub infra@192.168.1.150:~/.ssh/id_ed25519_proxmox.pub
```

### 4. LXC1 (infra-mgmt): Terraform key injection
Set the public key path used by Terraform in your `common.auto.tfvars`:
```hcl
ssh_public_key_path = "~/.ssh/id_ed25519_proxmox.pub"
```
Terraform injects this public key into each new LXC at creation time via the Proxmox initialization block. No private keys are stored on the LXCs.

### 5. LXC1 (infra-mgmt): Ansible with SSH agent forwarding
Ensure Ansible keeps agent forwarding enabled in `ansible.cfg`:
```ini
[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o ForwardAgent=yes -o IdentitiesOnly=no
```

### 6. Verify agent forwarding and key-only SSH
After logging into LXC1 with agent forwarding enabled:
```bash
infra@infra-mgmt:~$ ssh-add -l
infra@infra-mgmt:~$ cd ~/infra/ansible
infra@infra-mgmt:~$ ansible -m ping all -i inventory/hosts.ini
```

---

## Traefik Trust (Local Browser)
Since we are using a self-signed wildcard certificate for our homelab domain (`homelab118.home`), we must explicitly trust it on our local machine to remove browser security warnings.

```bash
# 1. Pull the newly generated cert to your local machine
scp root@192.168.1.122:/etc/traefik/certs/traefik.crt ./traefik.crt

# 2. Clean out old conflicting certs from Chrome's database
certutil -d sql:$HOME/.pki/nssdb -D -n "traefik" || true

# 3. Import the new correct cert into Chrome's trust store
certutil -d sql:$HOME/.pki/nssdb -A -t "C,," -n "traefik" -i ./traefik.crt

# 4. Add to OS System Trust (Ubuntu/Debian) securely
sudo cp ./traefik.crt /usr/local/share/ca-certificates/traefik.crt
sudo update-ca-certificates
```
*Note: Fully close and reopen Chrome for the trusted certificate to take effect.*
