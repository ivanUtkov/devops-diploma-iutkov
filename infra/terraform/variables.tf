variable "cloud_id" {
  type        = string
  description = "Yandex Cloud cloud id"
}

variable "folder_id" {
  type        = string
  description = "Yandex Cloud folder id"
}

variable "zone" {
  type        = string
  description = "Yandex Cloud availability zone, e.g. ru-central1-a"
  default     = "ru-central1-a"
}

variable "vm_user" {
  type        = string
  description = "Username for SSH access to the VM"
  default     = "ubuntu"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for VM access (contents of *.pub file)"
}

variable "network_id" {
  type        = string
  description = "Existing VPC network id"
}

variable "subnet_id" {
  type        = string
  description = "Existing subnet id in the chosen zone"
}