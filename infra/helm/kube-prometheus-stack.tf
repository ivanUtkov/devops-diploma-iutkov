resource "helm_release" "kps" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "61.2.0"

  namespace  = "monitoring"
  create_namespace = true

  values = [<<-YAML
grafana:
  service:
    type: LoadBalancer
  adminPassword: "admin123456"
YAML
  ]

  depends_on = [yandex_kubernetes_node_group.nodes]
}
