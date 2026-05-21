output "streaming_vm_id" {
  value       = module.streaming.vm_id
  description = "Streaming server container ID"
}

output "streaming_hostname" {
  value       = module.streaming.hostname
  description = "Streaming server hostname"
}

output "streaming_ipv4" {
  value       = module.streaming.ipv4_address
  description = "Streaming server IPv4 address"
}
