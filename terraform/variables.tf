variable "ssh_public_key" {
  description = "Clé SSH publique injectée par Cloud-Init dans la VM"
  type        = string
}

# Ajoute aussi celles-ci si tu les utilises dans ton provider.tf
variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type      = string
  sensitive = true
}