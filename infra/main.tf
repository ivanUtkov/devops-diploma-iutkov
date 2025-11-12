# 1) Сервисный аккаунт и роли
resource "yandex_iam_service_account" "sa" {
  name = var.sa_name
}

resource "yandex_resourcemanager_folder_iam_member" "sa-editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

# 2) VPC
resource "yandex_vpc_network" "net" {
  name = var.network_name
}

resource "yandex_vpc_subnet" "subnet" {
  name           = "${var.network_name}-subnet"
  zone           = var.zone
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = [var.subnet_cidr]
}

# 3) Kubernetes cluster + node group
resource "yandex_kubernetes_cluster" "mks" {
  name        = var.cluster_name
  network_id  = yandex_vpc_network.net.id
  master {
    regional {
      region = "ru-central1"
    }
    public_ip = true
    security_group_ids = []
  }

  service_account_id      = yandex_iam_service_account.sa.id
  node_service_account_id = yandex_iam_service_account.sa.id
  release_channel         = "RAPID"
  network_policy_provider = "CALICO"

  version = var.k8s_version

  depends_on = [yandex_resourcemanager_folder_iam_member.sa-editor]
}

resource "yandex_kubernetes_node_group" "nodes" {
  cluster_id  = yandex_kubernetes_cluster.mks.id
  name        = "${var.cluster_name}-ng"
  version     = var.k8s_version
  allocation_policy {
    location {
      zone = var.zone
    }
  }
  scale_policy {
    fixed_scale {
      size = var.node_count
    }
  }
  instance_template {
    platform_id = "standard-v3"
    resources {
      cores         = var.node_cores
      memory        = var.node_memory_gb
      core_fraction = 100
    }
    boot_disk {
      type = "network-ssd"
      size = 50
    }
    network_interface {
      subnet_ids = [yandex_vpc_subnet.subnet.id]
      nat        = true
    }
  }
  depends_on = [yandex_kubernetes_cluster.mks]
}

# 4) Object Storage (бакет)
resource "yandex_storage_bucket" "bucket" {
  bucket = var.bucket_name
  acl    = "private"
  anonymous_access_flags {
    read = false
    list = false
  }
}

# 5) Container Registry
resource "yandex_container_registry" "registry" {
  name = var.registry_name
}

# 6) Достаём kubeconfig для провайдеров
data "yandex_kubernetes_cluster" "mks_data" {
  cluster_id = yandex_kubernetes_cluster.mks.id
}

data "yandex_kubernetes_node_group" "nodes_data" {
  node_group_id = yandex_kubernetes_node_group.nodes.id
}

# kubeconfig (динамически) — провайдер kubernetes
provider "kubernetes" {
  host                   = data.yandex_kubernetes_cluster.mks_data.master[0].external_v4_endpoint
  cluster_ca_certificate = base64decode(data.yandex_kubernetes_cluster.mks_data.master[0].cluster_ca_certificate)
  token                  = data.yandex_kubernetes_cluster.mks_data.master[0].id_token
}

# helm провайдер — использует те же креды
provider "helm" {
  kubernetes {
    host                   = data.yandex_kubernetes_cluster.mks_data.master[0].external_v4_endpoint
    cluster_ca_certificate = base64decode(data.yandex_kubernetes_cluster.mks_data.master[0].cluster_ca_certificate)
    token                  = data.yandex_kubernetes_cluster.mks_data.master[0].id_token
  }
}
