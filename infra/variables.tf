variable "cloud_id" { type = string }
variable "folder_id" { type = string }
variable "zone"      { type = string  default = "ru-central1-a" }

variable "k8s_version" { type = string  default = "1.29" }
variable "cluster_name" { type = string default = "diploma-mks" }
variable "network_name" { type = string default = "diploma-net" }
variable "subnet_cidr"  { type = string default = "10.10.0.0/24" }

variable "sa_name"        { type = string default = "sa-diploma" }
variable "bucket_name"    { type = string default = "diploma-load-reports" }
variable "registry_name"  { type = string default = "diploma-registry" }

# Размер нод
variable "node_cores"     { type = number default = 2 }
variable "node_memory_gb" { type = number default = 4 }
variable "node_count"     { type = number default = 2 }
