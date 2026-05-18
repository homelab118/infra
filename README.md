
# Homelab Infrastructure as Code

This repo provisions a lightweight Proxmox LXC for Traefik and configures it with Ansible. The first service is a dedicated reverse proxy container running Traefik directly (no Docker).

## Structure
```
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
```
## Naming conventions

- Folders and playbooks: kebab-case
- Ansible group names and variables: snake_case
- Terraform module names: snake_case
- VMID scheme: 100-199 infra LXCs (reverse-proxy=110), 200-299 app LXCs, 300-399 storage/monitoring, 900-999 temp

## Bootstrap: SSH Agent Forwarding (Local -> LXC1 -> LXC2)

This workflow keeps the private key only on your local machine. LXC1 (infra-mgmt) stores the public key for Terraform to inject into new LXCs (LXC2), and Ansible uses SSH agent forwarding to authenticate without private keys on LXC1 or LXC2.

### 1. Local machine: create key + enable agent forwarding

Generate a dedicated ED25519 key for the homelab if it does not exist:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_proxmox -C "homelab-proxmox"
```

Add a wildcard SSH config so all 192.168.1.* hosts use the key and forward the agent:

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
ssh-copy-id -i ~/.ssh/id_ed25519_proxmox.pub root@192.168.1.X
```

Note: `authorized_keys` is the required filename on the server. Do not rename it.

### 3. Local machine -> LXC1: copy the public key for Terraform

Copy only the public key to LXC1 so Terraform can read it:

```bash
scp ~/.ssh/id_ed25519_proxmox.pub infra@infra-mgmt:~/.ssh/id_ed25519_proxmox.pub
```

### 4. LXC1 (infra-mgmt): Terraform key injection

Set the public key path used by Terraform on LXC1:

```hcl
# terraform/environments/homelab/terraform.tfvars
ssh_public_key_path = "~/.ssh/id_ed25519_proxmox.pub"
```

Terraform injects this public key into each new LXC at creation time via the Proxmox initialization block. No private keys are stored on LXC1 or LXC2.

Apply Terraform from LXC1:

```bash
infra@infra-mgmt:~$ cd /path/to/infra/terraform/environments/homelab
infra@infra-mgmt:~$ terraform init
infra@infra-mgmt:~$ terraform apply
```

### 5. LXC1 (infra-mgmt): Ansible with SSH agent forwarding

Ensure Ansible keeps agent forwarding enabled:

```ini
# ansible/ansible.cfg
[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=60s -o ForwardAgent=yes -o IdentitiesOnly=no
```

When using agent forwarding, do not set `ansible_ssh_private_key_file` in group vars.

### 6. LXC2: disable password SSH (Ansible snippet)

Add the following tasks to the playbook that configures LXC2:

```yaml
- name: Harden SSH settings
  ansible.builtin.lineinfile:
    path: /etc/ssh/sshd_config
    regexp: "^{{ item.key }}"
    line: "{{ item.key }} {{ item.value }}"
    create: false
  loop:
    - { key: "PasswordAuthentication", value: "no" }
    - { key: "ChallengeResponseAuthentication", value: "no" }
    - { key: "PermitRootLogin", value: "prohibit-password" }
  notify: Restart ssh

handlers:
  - name: Restart ssh
    ansible.builtin.service:
      name: ssh
      state: restarted
```

### 7. Verify agent forwarding and key-only SSH

After logging into LXC1 with agent forwarding enabled:

```bash
infra@infra-mgmt:~$ ssh-add -l
infra@infra-mgmt:~$ cd ~/infra/ansible
infra@infra-mgmt:~$ ansible -m ping reverse-proxy
```

On LXC2, confirm password auth is disabled:

```bash
sshd -T | grep -E 'passwordauthentication|challengeresponseauthentication|permitrootlogin'
```

Troubleshooting:

- If you see "No inventory was parsed", you are not in the `ansible` directory. Run `cd ~/infra/ansible` or pass `-i inventory/hosts.ini`.
- If SSH asks for a password from LXC1, make sure you logged into LXC1 with `ssh -A` and that LXC1 does not have `IdentityFile` or `IdentitiesOnly` set in `/root/.ssh/config` for `192.168.1.*`.

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
2. Verify `inventory/hosts.ini` has the correct LXC IP (default `192.168.1.122`).
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
scp root@192.168.1.122:/etc/traefik/certs/traefik.crt ./traefik.crt

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

> **Regenerating Certs:** If you change the domain name or need to regenerate the cert later, first delete them from the LXC (`ssh root@192.168.1.122 "rm -f /etc/traefik/certs/traefik.*"`), rerun the Ansible playbook, and repeat the local trust steps above.

## Defaults

- LXC: 1 vCPU, 512MB RAM, 8GB disk, 256MB swap
- IPv4: 192.168.1.122/24, gateway 192.168.1.1
- DNS: 192.168.1.90
- IPv6: auto (SLAAC)
- Template: ubuntu-24.04-standard_24.04-2_amd64.tar.zst
