#####################################
# Provider
#####################################

provider "yandex" {
  service_account_key_file = "sa-key.json"
  cloud_id                 = var.cloud_id
  folder_id                = var.folder_id
  zone                     = var.zone
}

#####################################
# Security group
#####################################

resource "yandex_vpc_security_group" "main" {
  name       = "diploma-sg"
  network_id = var.network_id

  # Разрешаем SSH
  ingress {
    protocol       = "TCP"
    description    = "SSH"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP для приложения (если понадобится 80)
  ingress {
    protocol       = "TCP"
    description    = "HTTP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # Порт приложения FastAPI (8000)
  ingress {
    protocol       = "TCP"
    description    = "FastAPI app"
    port           = 8000
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # Grafana (3000)
  ingress {
    protocol       = "TCP"
    description    = "Grafana"
    port           = 3000
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # Kibana (5601)
  ingress {
    protocol       = "TCP"
    description    = "Kibana"
    port           = 5601
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # Prometheus (9090)
  ingress {
    protocol       = "TCP"
    description    = "Prometheus"
    port           = 9090
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  # Разрешаем исходящий трафик
  egress {
    protocol       = "ANY"
    description    = "Any egress"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

#####################################
# Image
#####################################

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

#####################################
# VM
#####################################

resource "yandex_compute_instance" "app" {
  name        = "diploma-app-vm"
  platform_id = "standard-v3"
  zone        = var.zone

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      size     = 20
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id          = var.subnet_id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.main.id]
  }

  metadata = {
    ssh-keys = "${var.vm_user}:${var.ssh_public_key}"
  }
}

#####################################
# Outputs
#####################################

output "vm_external_ip" {
  description = "External IP address of the app VM"
  value       = yandex_compute_instance.app.network_interface[0].nat_ip_address
}
