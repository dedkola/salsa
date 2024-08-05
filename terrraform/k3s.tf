terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "3.0.1-rc3"
    }
  }
  required_version = ">= 0.14"
}

provider "proxmox" {
    pm_tls_insecure = true
    pm_api_url = "https://192.168.0.4:8006/api2/json/"
    pm_api_token_secret = "0a8cc609-9c4e-47d8-959d-e16fb188a70f"
    pm_api_token_id = "root@pam!ct"
}
resource "proxmox_vm_qemu" "k3s-master" {
  
    target_node = "px"
    desc = "Cloudinit Ubuntu"
    count = 3
    clone = "ubuntu-cloud"
    full_clone = true
    agent = 1
    vm_state = "stopped"
    os_type = "cloud-init"
    tags="k3s,master,ubuntu"
    cores = 2
    sockets = 1
    numa = true
    vcpus = 0
    cpu = "host"
    memory = 4096
    name = "k3s-master-0${count.index + 1}"
    scsihw = "virtio-scsi-pci"
    bootdisk = "scsi0"

     disks {
        ide {
            ide3 {
                cloudinit {
                    storage = "local-lvm"
                }
            }
        }
        scsi {
            scsi0 {
                disk {
                    size            = 32
                    cache           = "writeback"
                    storage         = "local-lvm"
                    iothread        = true
                    discard         = true
                }
            }
        }
    }
     
    ciuser = "usr"
    cipassword = "123"
    ipconfig0 = "ip=192.168.0.11${count.index + 1}/24,gw=192.168.0.1"
    sshkeys = <<EOF
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCjUkRF+68kpg+hMkRsIxfgyHwu6MZeo9ddZ99o5pSYPAcvzMiYkuN7zLIloFEPOLbHTYw9PhVfaHtNtdIWwr2XLvgAzdy3jcdVdBQ9yYaDyNkrXd7c0YyvWQzAWLy8J3E9nG1l9cgTVHdsLw5J5MAbZKERDIriVAytOWscj4SsRwxtcHH1+HqF4XMIa4lmwtTES/2WUVPVBt1Vaf14Gdr5IJOuLpDeW/qQGbTmVgXDJzcEU1oYsmtW2LBdIZo436JlXKEsyyWFZW9i8TtuDCkuhFDKts2AKipQbz4JhOOsELKxbyWUGY2VBWuqEJThKQ5GyNuVd0JXZ2KD2UCaWjiwTsLxecely54NaWULZDT/YOIoXHVbYJomK8f40tvBj4Z7JKZBllniuwBoIBdobMkppcr0/QiM5ipRUSc8s83Km3xJ/0dKM2kkbyza7ofEGR3OsOFpDb/iT1xg9CEOY9McMsJmM51PnyqMX/fqvxZdDZeIZqKNN6wKf/2GuJl6XXM= usr@local 
    EOF
}

resource "proxmox_vm_qemu" "k3s-node" {
  
    target_node = "px"
    desc = "Cloudinit Ubuntu"
    count = 3
    clone = "ubuntu-cloud"
    full_clone = true
    agent = 1
    vm_state = "stopped"
    os_type = "cloud-init"
    tags="k3s,node,ubuntu"
    cores = 2
    sockets = 1
    numa = true
    vcpus = 0
    cpu = "host"
    memory = 4096
    name = "k3s-node-0${count.index + 1}"
    scsihw = "virtio-scsi-pci"
    bootdisk = "scsi0"

     disks {
        ide {
            ide3 {
                cloudinit {
                    storage = "local-lvm"
                }
            }
        }
        scsi {
            scsi0 {
                disk {
                    size            = 32
                    cache           = "writeback"
                    storage         = "local-lvm"
                    iothread        = true
                    discard         = true
                }
            }
        }
    }
     
    ciuser = "usr"
    cipassword = "123"
    ipconfig0 = "ip=192.168.0.10${count.index + 1}/24,gw=192.168.0.1"
    sshkeys = <<EOF
    ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCjUkRF+68kpg+hMkRsIxfgyHwu6MZeo9ddZ99o5pSYPAcvzMiYkuN7zLIloFEPOLbHTYw9PhVfaHtNtdIWwr2XLvgAzdy3jcdVdBQ9yYaDyNkrXd7c0YyvWQzAWLy8J3E9nG1l9cgTVHdsLw5J5MAbZKERDIriVAytOWscj4SsRwxtcHH1+HqF4XMIa4lmwtTES/2WUVPVBt1Vaf14Gdr5IJOuLpDeW/qQGbTmVgXDJzcEU1oYsmtW2LBdIZo436JlXKEsyyWFZW9i8TtuDCkuhFDKts2AKipQbz4JhOOsELKxbyWUGY2VBWuqEJThKQ5GyNuVd0JXZ2KD2UCaWjiwTsLxecely54NaWULZDT/YOIoXHVbYJomK8f40tvBj4Z7JKZBllniuwBoIBdobMkppcr0/QiM5ipRUSc8s83Km3xJ/0dKM2kkbyza7ofEGR3OsOFpDb/iT1xg9CEOY9McMsJmM51PnyqMX/fqvxZdDZeIZqKNN6wKf/2GuJl6XXM= usr@local 
    EOF
}


