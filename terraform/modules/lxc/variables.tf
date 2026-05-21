variable "node_name" {
  type        = string
  description = "Proxmox node name"
}

variable "vm_id" {
  type        = number
  description = "LXC container ID"
}

variable "hostname" {
  type        = string
  description = "LXC hostname"
}

variable "datastore_id" {
  type        = string
  description = "Storage for the container rootfs"
}

variable "template_datastore_id" {
  type        = string
  description = "Storage where the template is kept"
}

variable "bridge" {
  type        = string
  description = "Proxmox bridge for the container network interface"
}

variable "ipv4_address" {
  type        = string
  description = "IPv4 address in CIDR notation"
}

variable "ipv4_gateway" {
  type        = string
  description = "IPv4 gateway"
}

variable "ipv6_address" {
  type        = string
  description = "IPv6 address in CIDR notation, or dhcp/auto"
  default     = "auto"
}

variable "dns_servers" {
  type        = list(string)
  description = "DNS servers"
  default     = []
}

variable "ssh_public_keys" {
  type        = list(string)
  description = "SSH public keys for the root account"
  default     = []
}

variable "root_password" {
  type        = string
  description = "Optional root password"
  default     = null
  sensitive   = true
}

variable "disk_size_gb" {
  type        = number
  description = "Rootfs size in GB"
  default     = 8
}

variable "memory_mb" {
  type        = number
  description = "Dedicated memory in MB"
  default     = 512
}

variable "swap_mb" {
  type        = number
  description = "Swap size in MB"
  default     = 256
}

variable "cpu_cores" {
  type        = number
  description = "CPU cores"
  default     = 1
}

variable "unprivileged" {
  type        = bool
  description = "Run container unprivileged"
  default     = true
}

variable "start_on_boot" {
  type        = bool
  description = "Start container on host boot"
  default     = true
}

variable "started" {
  type        = bool
  description = "Start container after creation"
  default     = true
}

variable "template_file_name" {
  type        = string
  description = "Template filename (vztmpl)"
}

variable "template_url" {
  type        = string
  description = "Template download URL"
}

variable "template_file_id" {
  type        = string
  description = "Existing template file ID to use instead of download"
  default     = null
}

variable "template_verify" {
  type        = bool
  description = "Verify TLS certificates when downloading the template"
  default     = true
}

variable "tags" {
  type        = list(string)
  description = "Container tags"
  default     = []
}

variable "nesting" {
  type        = bool
  description = "Enable nesting (required for Ubuntu 22.04+ systemd)"
  default     = true
}
