variable "promox_vm_name" {
type = string
default= "ubuntu-22-04-vm"
}

variable "promox_vm_ip" {
  type = string
  default= "dhcp"
}

#variable "promox_vm_gateway" {
#  type = string
#}

variable "promox_vm_nameserver" {
  type = string
  default= "192.168.1.95"
}

variable "proxmox_target_node" {
  default = "pve"
}

variable "promox_template_name" {
  default = "ubuntu-clouding-server-22-04-template-devops"
}
  
variable "promox_api_url" {
  type = string
}

variable "promox_api_token_id" {
  type = string
}

variable "promox_api_token_secret" {
  type = string
}

variable "public_key" {}

variable "user_name" {
  type = string
}

variable "user_password" {
  type = string
}

variable "ram_name" {
  type = string
  default = "2g"
}

variable "ram_size" {
  type = number
  default = 2048
}


terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.1-rc1"
    }
  }
}

resource "random_string" "lower" {
  length  = 8
  upper   = false
  lower   = true
  numeric  = false
  special = false
}

# all variable must be previously entered in the VM template "config map" 

provider "proxmox" {
  pm_debug            = true
  pm_tls_insecure     = true
  pm_api_url          = var.promox_api_url
  pm_api_token_id     = var.promox_api_token_id
  pm_api_token_secret = var.promox_api_token_secret
  pm_log_file   = "terraform-plugin-proxmox.log"
  pm_log_levels = {
    _default = "debug"
    _capturelog = ""
 }
}


resource "proxmox_vm_qemu" "classdevops24_learn_platform" {
  
  name        = "${var.promox_vm_name}-${random_string.lower.result}"
  target_node = var.proxmox_target_node
  agent       = 1
  clone       = "${var.promox_template_name}-${var.ram_name}"
  cores       = 2
  sockets     = 1
  cpu         = "host"
  memory      = var.ram_size

  scsihw      = "virtio-scsi-single"
  bootdisk = "scsi0"
  cloudinit_cdrom_storage = "local-lvm"
  
   disks {
    scsi {
      scsi0 {
        disk {
          size = 30
          storage = "local-lvm"
        }
      }
    }
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  os_type      = "cloud-init"
  ciuser       = var.user_name
  cipassword   = var.user_password
  #ipconfig0    = "ip=${var.promox_vm_ip},gw=${var.promox_vm_gateway}"
  ipconfig0    = "ip=${var.promox_vm_ip}"
  nameserver   = var.promox_vm_nameserver
  sshkeys = <<-EOF
    ${var.public_key}
  EOF
  ssh_user = var.user_name


  lifecycle {
    ignore_changes = [
      network,
    ]
  }

}


output "private_ip" {
  value = proxmox_vm_qemu.classdevops24_learn_platform.default_ipv4_address
}

output "public_ip" {
  value = proxmox_vm_qemu.classdevops24_learn_platform.default_ipv4_address
}

output "hostname" {
  value = proxmox_vm_qemu.classdevops24_learn_platform.name
}
