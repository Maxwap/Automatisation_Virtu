locals {
  vms = {
    "pg-master"  = { id = 9101, ip = "10.0.10.101", ram = 2048, cores = 2, node = "pve-01" }
    "pg-slave-1" = { id = 9102, ip = "10.0.10.102", ram = 2048, cores = 2, node = "pve-01" } 
    "pg-slave-2" = { id = 9103, ip = "10.0.10.103", ram = 2048, cores = 2, node = "pve-01" }
    "haproxy-lb" = { id = 9104, ip = "10.0.10.104", ram = 1024, cores = 1, node = "pve-01" } 
  }
}

resource "proxmox_vm_qemu" "vms" {
  for_each    = local.vms
  name        = each.key
  vmid        = each.value.id
  target_node = each.value.node
  pool        = "Virtu"

  clone      = "template13" # 🎯 Ton vrai nom de template !
  full_clone = true

  # 🎯 On force le boot sur le disque SCSI qu'on va créer en dessous
  boot = "order=scsi0"

  agent = 1

  cpu {
    cores = each.value.cores
    type  = "host"
  }
  memory = each.value.ram
  os_type = "cloud-init"

  # 🎯 On passe de virtio-block à SCSI (comme sur ta capture Proxmox !)
  scsihw = "virtio-scsi-pci"

  disks {
    scsi {
      scsi0 {
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
    tag= "10"
  }

  ipconfig0 = "ip=${each.value.ip}/24,gw=10.0.10.254"

  sshkeys = <<EOF
${var.ssh_public_key}
EOF
}