output "vm_ips" {
  description = "Adresses IPs des machines virtuelles déployées"
  value = {
    for name, vm in proxmox_vm_qemu.vms : name => vm.default_ipv4_address
  }
}