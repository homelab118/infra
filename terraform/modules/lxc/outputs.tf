output "vm_id" {
  value       = proxmox_virtual_environment_container.this.vm_id
  description = "Container ID"
}

output "hostname" {
  value       = var.hostname
  description = "Container hostname"
}

output "ipv4_addresses" {
  value       = proxmox_virtual_environment_container.this.ipv4
  description = "IPv4 addresses by interface"
}

output "ipv6_addresses" {
  value       = proxmox_virtual_environment_container.this.ipv6
  description = "IPv6 addresses by interface"
}

output "ipv4_address" {
  value       = proxmox_virtual_environment_container.this.ipv4["veth0"]
  description = "Primary IPv4 address"
}
