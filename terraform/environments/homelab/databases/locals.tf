locals {
  lxc_template_url = coalesce(
    var.lxc_template_url,
    "https://download.proxmox.com/images/system/${var.lxc_template_file_name}"
  )
}
