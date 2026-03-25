resource "proxmox_vm_qemu" "ma_vm_test" {
  name        = "debian-test-01"
  target_node = "pve-01" 
  vmid        = 9001
  pool        = "Virtu"

  clone      = "template-debian-12" 
  full_clone = true

  cpu { cores = 1 }
  memory = 1024 

  os_type   = "cloud-init" 
  
  
  ipconfig0 = "ip=10.0.10.100/24,gw=10.0.10.254" 

  # Injection de ta clé SSH depuis tes variables masquées
  sshkeys = <<EOF
  ${var.ssh_public_key}
  EOF
}