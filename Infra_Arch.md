# Homelab Network & Infrastructure Reference

## Overview

### Physical Nodes

| Device | Hostname | IP Address | Role |
|---------|----------|------------|------|
| HP Mini PC | pve-main.homelab118.home | 192.168.1.110 | Main Proxmox node |
| Sony Laptop | pve-backup.homelab118.home | 192.168.1.111 | Secondary Proxmox node |

---

## Network Configuration

| Setting | Value |
|----------|-------|
| Network | 192.168.1.0/24 |
| Gateway | 192.168.1.1 |
| DHCP Range | 192.168.1.2 – 192.168.1.101 |
| Static Infrastructure Range | 192.168.1.110 – 192.168.1.199 |
| DNS Domain | homelab118.home |

---

## IP Allocation Strategy

### 192.168.1.110 – 119
Hypervisors

### 192.168.1.120 – 129
Networking / Access Services

### 192.168.1.130 – 149
Applications

### 192.168.1.150 – 159
Infrastructure / Automation

### 192.168.1.160 – 169
Monitoring

### 192.168.1.170 – 179
Kubernetes / Cluster

### 192.168.1.180 – 199
Testing / Temporary

---

# Current Infrastructure

| VMID | Service | Hostname | IP Address | Category |
|------|----------|----------|------------|----------|
| 100 | pi-hole | dns.homelab118.home | 192.168.1.120 | Networking |
| 101 | twingate-connector | twingate.homelab118.home | 192.168.1.121 | Networking |
| 110 | reverse-proxy | proxy.homelab118.home | 192.168.1.122 | Networking |
| 202 | streaming-server | streaming.homelab118.home | 192.168.1.130 | Application |
| 206 | server-docker | docker.homelab118.home | 192.168.1.131 | Application |
| 207 | jenkins | jenkins.homelab118.home | 192.168.1.132 | Application |
| 300 | postgres | postgres.homelab118.home | 192.168.1.140 | Database |
| 400 | infra-mgmt | infra.homelab118.home | 192.168.1.150 | Infrastructure |

---

# Planned Services

## Monitoring Stack

| VMID | Service | Hostname | IP Address |
|------|----------|----------|------------|
| 600 | prometheus | prometheus.homelab118.home | 192.168.1.160 |
| 601 | grafana | grafana.homelab118.home | 192.168.1.161 |
| 602 | loki | loki.homelab118.home | 192.168.1.162 |

---

## Infrastructure / Automation

| VMID | Service | Hostname | IP Address |
|------|----------|----------|------------|
| 401 | ansible-runner | ansible.homelab118.home | 192.168.1.151 |
| 402 | gitops | gitops.homelab118.home | 192.168.1.152 |

---

## Kubernetes / Cluster Lab

| VMID | Service | Hostname | IP Address |
|------|----------|----------|------------|
| 500 | k3s-master | k3s-master.homelab118.home | 192.168.1.170 |
| 501 | k3s-worker-1 | k3s-worker.homelab118.home | 192.168.1.171 |
| 510 | docker-lab | docker-lab.homelab118.home | 192.168.1.172 |

---

## Future Applications

| VMID | Service | Hostname | IP Address |
|------|----------|----------|------------|
| 208 | gitea | gitea.homelab118.home | 192.168.1.133 |
| 209 | registry | registry.homelab118.home | 192.168.1.134 |
| 210 | vault | vault.homelab118.home | 192.168.1.135 |

---

# Proxmox VMID Allocation Standard

| Range | Purpose |
|--------|---------|
| 100–149 | Networking / Access |
| 200–249 | Applications |
| 300–349 | Databases |
| 400–449 | Infrastructure |
| 500–599 | Cluster / Labs |
| 600–699 | Monitoring |
| 700–799 | Kubernetes |
| 900–999 | Temporary / Testing |

---

# Naming Convention

## Hypervisors

pve-main.homelab118.home  
pve-backup.homelab118.home

## Infrastructure

proxy.homelab118.home  
infra.homelab118.home  
adguard.homelab118.home

## Applications

docker.homelab118.home  
jenkins.homelab118.home  
streaming.homelab118.home

## Databases

postgres.homelab118.home

---

# Notes

- Keep DHCP devices below 192.168.1.101
- All servers use static IPs
- Use `homelab118.home` for internal DNS
- Reserve 180–199 for temporary deployments
- New services should follow VMID category allocation