terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.66.3"
    }
  }
}

provider "proxmox" {
  endpoint = "https://192.168.1.100:8006/"
  api_token = var.pm_api_token
  insecure = true
}