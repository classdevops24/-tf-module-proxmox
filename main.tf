variable "public_key" {}
variable "name" {}
variable "ip" {
  type = string
}
variable "gateway" {
  type = string
}
# TLS Resource-a ere soberan izango genuke kasu honetan

terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = ">= 2.9.5"
    }
  }
  required_version = ">= 0.14.0"
}

resource "tls_private_key" "temporary" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# The following pm_api_url, token_id and secret must be previously entered in the VM template "config map" in the administrator panel or leave it in environments

provider "proxmox" {
  pm_debug            = false
  pm_tls_insecure     = true
  pm_api_url          = ${var.pm_api_url}
  pm_api_token_id     = ${var.pm_api_token_id}
  pm_api_token_secret = ${var.pm_api_token_secret}
}


resource "proxmox_vm_qemu" "hobbyfarm" {

  name        = var.name
  target_node = ${var.target_node}
  agent       = 1
  clone       = "ubuntu18-template"
  cores       = 2
  sockets     = 1
  cpu         = "host"
  memory      = 4096

  scsihw      = "virtio-scsi-pci"

  vga {
    type = "std"
  }

  disk {
    size            = "10G"
    type            = "virtio"
    storage         = "vz2TB"
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  os_type      = "cloud-init"
  ciuser       = "user"
  cipassword   = "user"
  ipconfig0    = "ip=${var.ip}/24,gw=${var.gateway}"
  nameserver   = "8.8.8.8"
  sshkeys = <<-EOF
    ${tls_private_key.temporary.public_key_openssh}
    ${var.public_key}
  EOF
  ssh_user = "user"


  lifecycle {
    ignore_changes = [
      network,
    ]
  }

provisioner "remote-exec" {
  inline = [
      "sleep 10",
      #"sudo ip a | grep \"inet \" | grep -v 127.0.0.1 | head -n1 | awk '{print $2}' | cut -d '/'",
      #"Oraingoz ez dut erabiliko guzti hau",
      "sleep 10"
      ]

  connection {
    type        = "ssh"
    host        = var.ip
    user        = "user"
    password    = ""
    private_key = tls_private_key.temporary.private_key_pem
  }

  }
}


output "private_ip" {
  value = proxmox_vm_qemu.hobbyfarm.default_ipv4_address
}

output "public_ip" {
  value = proxmox_vm_qemu.hobbyfarm.default_ipv4_address
}

output "hostname" {
  value = proxmox_vm_qemu.hobbyfarm.name
}
