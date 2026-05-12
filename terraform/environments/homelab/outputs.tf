output "reverse_proxy_vm_id" {
  value       = module.reverse_proxy.vm_id
  description = "Reverse proxy container ID"
}

output "reverse_proxy_hostname" {
  value       = module.reverse_proxy.hostname
  description = "Reverse proxy hostname"
}

output "reverse_proxy_ipv4" {
  value       = module.reverse_proxy.ipv4_address
  description = "Reverse proxy IPv4 address"
}

output "reverse_proxy_ipv4_map" {
  value       = module.reverse_proxy.ipv4_addresses
  description = "All IPv4 addresses by interface"
}

output "reverse_proxy_ipv6_map" {
  value       = module.reverse_proxy.ipv6_addresses
  description = "All IPv6 addresses by interface"
}
