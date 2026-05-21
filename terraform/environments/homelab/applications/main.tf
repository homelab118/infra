data "local_file" "ssh_key" {
  filename = pathexpand(var.ssh_public_key_path)
}

module "streaming" {
  source = "../../../modules/lxc"

  node_name             = var.lxc_node_name
  vm_id                 = 202
  hostname              = "streaming"
  datastore_id          = var.lxc_datastore_id
  template_datastore_id = var.lxc_template_datastore_id
  bridge                = var.lxc_bridge
  ipv4_address          = "192.168.1.130/24"
  ipv4_gateway          = var.lxc_ipv4_gateway
  ipv6_address          = var.lxc_ipv6_address
  dns_servers           = var.lxc_dns_servers
  ssh_public_keys       = [trimspace(data.local_file.ssh_key.content)]
  root_password         = var.lxc_root_password
  disk_size_gb          = 16
  memory_mb             = 4096
  swap_mb               = 1024
  cpu_cores             = 4
  unprivileged          = false # Must be privileged for easy GPU passthrough
  nesting               = false # Proxmox API tokens cannot set nesting=true on privileged LXCs
  start_on_boot         = var.lxc_start_on_boot
  started               = var.lxc_started
  template_file_id      = var.lxc_template_file_id
  template_file_name    = var.lxc_template_file_name
  template_url          = local.lxc_template_url
  template_verify       = var.lxc_template_verify
  tags                  = ["application", "plex"]
}
