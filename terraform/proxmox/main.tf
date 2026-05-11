resource "proxmox_virtual_environment_vm" "ubuntu_vm" {
  name      = "docker-test"
  node_name = "pve"

  clone {
    vm_id = 9000
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 4096
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      username = "ubuntu"

      
    }
  }
}