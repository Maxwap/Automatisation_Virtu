resource "proxmox_vm_qemu" "ma_vm_test" {
  name        = "debian-test-01"
  target_node = "pve-01" 
  vmid        = 9001
  pool        = "Virtu"

  clone      = "template-debian-12" 
  full_clone = true

  cpu { cores = 1 }
  memory = 1024 resource "proxmox_vm_qemu" "ma_vm_test" {
  name        = "debian-test-01"
  target_node = "pve-01" 
  vmid        = 9001
  pool        = "Virtu"

  clone      = "template-debian-12" 
  full_clone = true

  cpu { cores = 1 }
  memory = 1024 

  os_type   = "cloud-init" 

  # 🔥 Voici la syntaxe exacte pour définir les disques et le cloud-init
  disks {
    scsi {
      scsi0 {
        disk {
          size    = "20G"
          storage = "local-lvm" # <-- Adapte si ton stockage s'appelle autrement (ex: nvme-storage)
        }
      }
    }
    ide {
      ide2 {
        cloudinit {
          storage = "local-lvm" # <-- C'est ici qu'on définit le lecteur Cloud-init !
        }
      }
    }
  }

  ipconfig0 = "ip=10.0.10.100/24,gw=10.0.10.254" 

  sshkeys = <<EOF
  ${var.ssh_public_key}
  EOF
}

  os_type   = "cloud-init" 

  
  ipconfig0 = "ip=10.0.10.100/24,gw=10.0.10.254" 

  # Injection de ta clé SSH depuis tes variables masquées
  sshkeys = <<EOF
  ${var.ssh_public_key}
  EOF
}