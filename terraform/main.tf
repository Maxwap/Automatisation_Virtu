resource "proxmox_vm_qemu" "ma_vm_test" {
  name        = "debian-test-01"
  target_node = "pve-01" 
  vmid        = 9001
  pool        = "Virtu"

  clone      = "debian12-cloud"
  full_clone = true

  cpu {
    cores = 2
    type  = "host"
  }
  memory = 2048 

  os_type = "cloud-init" 

  # 🔥 ON PASSE LE STOCKAGE EN VIRTIO 🔥
  disks {
    virtio {
      virtio0 {
        disk {
          size    = "20G"
          storage = "local-lvm"
        }
      }
    }
    ide {
      ide2 {
        cloudinit {
          storage = "local-lvm"
        }
      }
    }
  }

  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  ipconfig0 = "ip=10.0.10.100/24,gw=10.0.10.254" 

  sshkeys = <<EOF
${var.ssh_public_key}
EOF
}