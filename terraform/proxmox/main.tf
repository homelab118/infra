resource "proxmox_virtual_environment_container" "ubuntu_lxc" {

  node_name = "pve"
  vm_id     = 500
  hostname  = "test-lxc"

  unprivileged = true
  started       = true

  operating_system {
    template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    type             = "ubuntu"
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
    swap      = 512
  }

  disk {
    datastore_id = "local-lvm"
    size         = 20
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  initialization {
    hostname = "test-lxc"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  features {
    nesting = true
  }
}