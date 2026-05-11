resource "proxmox_virtual_environment_container" "ubuntu_lxc" {

  description = "Managed by Terraform"

  node_name = "proxmox"
  vm_id     = 500

  unprivileged = true
  started       = false
  start_on_boot = true

  features {
    nesting = true
  }

  initialization {

    hostname = "test-lxc"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      keys = [
        trimspace(file("~/.ssh/id_ed25519.pub"))
      ]
    }
  }

  network_interface {
    name   = "veth0"
    bridge = "vmbr0"
  }

  disk {
    datastore_id = "local-lvm"
    size         = 8
  }

  memory {
    dedicated = 1024
    swap      = 512
  }

  cpu {
    cores = 2
  }

  operating_system {
    template_file_id = "local:vztmpl/ubuntu-24.04-standard_24.04-2_amd64.tar.zst"
    type             = "ubuntu"
  }
}