resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "4.11.2"

  namespace  = "ingress-nginx"
  create_namespace = true

  values = [<<-YAML
controller:
  service:
    type: LoadBalancer
YAML
  ]

  depends_on = [yandex_kubernetes_node_group.nodes]
}
