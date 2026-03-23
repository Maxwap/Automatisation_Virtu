variable "proxmox_api_url" {
  description = "URL de l'API Proxmox VE"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "ID du Token API Proxmox"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "Secret du Token API Proxmox"
  type        = string
  sensitive   = true
}
