terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
    }
  }
}

locals {
  lxc_template_file_id = coalesce(
    var.template_file_id,
    try(proxmox_download_file.lxc_template[0].id, null)
  )
}

resource "proxmox_download_file" "lxc_template" {
  count        = var.template_file_id == null ? 1 : 0
  content_type = "vztmpl"
  datastore_id = var.template_datastore_id
  node_name    = var.node_name
  url          = var.template_url
  file_name    = var.template_file_name
  overwrite    = false
  verify       = var.template_verify
}

resource "proxmox_virtual_environment_container" "this" {
  node_name     = var.node_name
  vm_id         = var.vm_id
  description   = "Managed by Terraform"
  tags          = var.tags
  unprivileged  = var.unprivileged
  start_on_boot = var.start_on_boot
  started       = var.started

  initialization {
    hostname = var.hostname

    ip_config {
      ipv4 {
        address = var.ipv4_address
        gateway = var.ipv4_gateway
      }

      ipv6 {
        address = var.ipv6_address
      }
    }

    dns {
      servers = var.dns_servers
    }

    user_account {
      keys     = var.ssh_public_keys
      password = var.root_password
    }
  }

  network_interface {
    name   = "veth0"
    bridge = var.bridge
  }

  disk {
    datastore_id = var.datastore_id
    size         = var.disk_size_gb
  }

  cpu {
    cores = var.cpu_cores
  }

  memory {
    dedicated = var.memory_mb
    swap      = var.swap_mb
  }

  operating_system {
    template_file_id = local.lxc_template_file_id
    type             = "ubuntu"
  }

  wait_for_ip {
    ipv4 = true
  }

  features {
    nesting = false
    keyctl  = false
  }
}
