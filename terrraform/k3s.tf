terraform {
  required_providers {
    proxmox = {
      source  = "registry.example.com/telmate/proxmox"
      version = ">=1.0.0"
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
    desc = "Ubuntu"
    count = 3
    onboot = true
    clone = "ss2"
    agent = 0
    os_type = "cloud-init"
    cores = 1
    sockets = 1
    numa = true
    vcpus = 0
    cpu = "host"
    memory = 4096
    name = "k3s-master-0${count.index + 1}"
    scsihw   = "virtio-scsi-single" 

    disks {
        scsi {
            scsi0 {
                disk {
                    backup             = true
                    cache              = "none"
                    discard            = true
                    emulatessd         = true
                    iothread           = true
                    mbps_r_burst       = 0.0
                    mbps_r_concurrent  = 0.0
                    mbps_wr_burst      = 0.0
                    mbps_wr_concurrent = 0.0
                    replicate          = true
                    size               = 32
                    storage            = "local-lvm"
                  
                }
            }
        }
    }


    ipconfig0 = "ip=192.168.0.70/24,gw=192.168.0.1"

    ciuser = "ded"
    nameserver = "2.2.2.2"
    sshkeys = <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDHZlTW1LaL/LBUCumOaPtnh4cuPe72VXJywnPO9PAp3v/kM0X1Hal3/I+bgVd5CbSlKyUylBC9RXHUXx0aZuloI0nsD+JJsPioWPe1k7TBbRXOd/IVWzaQ6hd0rdjs8PMYVRKVsWUs9TLH1Eicnp7tuwBWsbOrAV+3tqsZXrP0oYUWoeIknSy0dXP7UWZ5X96WjtF/zrjR6tb0SemtYn5E+zKPIVPFiHTkw5WD/CeYL/g1/97GFKqfidBqwRAW1Dxy7u6szkC122qERkiIuNlh4XqLJ+wEh/YlBTg+ZukGotBoR6RFjGkATkr4ad509qHOrafSfUaenLSSSvwGFv9haHhvpGe8ycLwwPIABPRWhLbBQ+UWYffjeEoOaSqxTtuxTy8jEvFJXGdZRA2njpNzewM6g/K8N2kmf7SkWCyDBemAa/EWuiiepO8kL5Syidp/VpFDanOQXIs4bCxTKMTjfWLiyLr1xMg1S9n/aSAaRyQcKff47D+RNm7aSwMBUv8= ded@ded
    EOF
}

resource "proxmox_vm_qemu" "k3s-worker" {

    target_node = "px"
    desc = "Ubuntu"
    count = 4
    onboot = true
    clone = "ss2"
    agent = 0
    os_type = "cloud-init"
    cores = 1
    sockets = 1
    numa = true
    vcpus = 0
    cpu = "host"
    memory = 4096
    name = "k3s-worker-0${count.index + 1}"
    scsihw   = "virtio-scsi-single" 
    disks {
        scsi {
            scsi0 {
                disk {
                  backup             = true
                    cache              = "none"
                    discard            = true
                    emulatessd         = true
                    iothread           = true
                    mbps_r_burst       = 0.0
                    mbps_r_concurrent  = 0.0
                    mbps_wr_burst      = 0.0
                    mbps_wr_concurrent = 0.0
                    replicate          = true
                    size               = 32
                    storage            = "local-lvm"
                }
            }
        }
    }

    ipconfig0 = "ip=192.168.0.80/24,gw=192.168.0.1"
    ciuser = "ubuntu"
    sshkeys = <<EOF
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDHZlTW1LaL/LBUCumOaPtnh4cuPe72VXJywnPO9PAp3v/kM0X1Hal3/I+bgVd5CbSlKyUylBC9RXHUXx0aZuloI0nsD+JJsPioWPe1k7TBbRXOd/IVWzaQ6hd0rdjs8PMYVRKVsWUs9TLH1Eicnp7tuwBWsbOrAV+3tqsZXrP0oYUWoeIknSy0dXP7UWZ5X96WjtF/zrjR6tb0SemtYn5E+zKPIVPFiHTkw5WD/CeYL/g1/97GFKqfidBqwRAW1Dxy7u6szkC122qERkiIuNlh4XqLJ+wEh/YlBTg+ZukGotBoR6RFjGkATkr4ad509qHOrafSfUaenLSSSvwGFv9haHhvpGe8ycLwwPIABPRWhLbBQ+UWYffjeEoOaSqxTtuxTy8jEvFJXGdZRA2njpNzewM6g/K8N2kmf7SkWCyDBemAa/EWuiiepO8kL5Syidp/VpFDanOQXIs4bCxTKMTjfWLiyLr1xMg1S9n/aSAaRyQcKff47D+RNm7aSwMBUv8= ded@ded
    EOF
}