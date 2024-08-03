#!/bin/bash

wget https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
qm create 8000 --memory 2048 --core 2 --name ubuntu-cloud --net0 virtio,bridge=vmbr0
qm disk import 8000 noble-server-cloudimg-amd64.img local
qm set 8000 --scsihw virtio-scsi-pci --scsi0 local:vm-8000-disk-0
qm set 8000 --ide2 local:cloudinit
qm set 8000 --boot c --bootdisk scsi0
qm set 8000 --serial0 socket --vga serial0
qm template 8000
qm clone 8000 135 --name ubuntu-cloud --full
