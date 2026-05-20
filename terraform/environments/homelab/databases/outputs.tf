output "postgres_vm_id" {
  value       = module.postgres.vm_id
  description = "Postgres container ID"
}

output "postgres_hostname" {
  value       = module.postgres.hostname
  description = "Postgres hostname"
}

output "postgres_ipv4" {
  value       = module.postgres.ipv4_address
  description = "Postgres IPv4 address"
}

output "postgres_ipv4_map" {
  value       = module.postgres.ipv4_addresses
  description = "All IPv4 addresses by interface"
}

output "postgres_ipv6_map" {
  value       = module.postgres.ipv6_addresses
  description = "All IPv6 addresses by interface"
}
