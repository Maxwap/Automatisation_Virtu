resource "proxmox_vm_qemu" "ma_vm_test" {
  name        = "debian-test-01"
  target_node = "pve" 
  vmid        = 9001

  clone      = "template-debian-13" 
  full_clone = true

  cores  = 1
  memory = 1024 

  os_type   = "cloud-init" 
  ipconfig0 = "ip=dhcp"    

}