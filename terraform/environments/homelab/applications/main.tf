data "local_file" "ssh_key" {
  filename = pathexpand(var.ssh_public_key_path)
}

module "streaming" {
  source = "../../../modules/lxc"

  node_name             = var.lxc_node_name
  vm_id                 = var.lxc_vm_id
  hostname              = var.lxc_hostname
  datastore_id          = var.lxc_datastore_id
  template_datastore_id = var.lxc_template_datastore_id
  bridge                = var.lxc_bridge
  ipv4_address          = var.lxc_ipv4_address
  ipv4_gateway          = var.lxc_ipv4_gateway
  ipv6_address          = var.lxc_ipv6_address
  dns_servers           = var.lxc_dns_servers
  ssh_public_keys       = [trimspace(data.local_file.ssh_key.content)]
  root_password         = var.lxc_root_password
  disk_size_gb          = var.lxc_disk_size_gb
  memory_mb             = var.lxc_memory_mb
  swap_mb               = var.lxc_swap_mb
  cpu_cores             = var.lxc_cpu_cores
  unprivileged          = var.lxc_unprivileged
  nesting               = var.lxc_nesting
  start_on_boot         = var.lxc_start_on_boot
  started               = var.lxc_started
  template_file_id      = var.lxc_template_file_id
  template_file_name    = var.lxc_template_file_name
  template_url          = local.lxc_template_url
  template_verify       = var.lxc_template_verify
  tags                  = var.lxc_tags
}
