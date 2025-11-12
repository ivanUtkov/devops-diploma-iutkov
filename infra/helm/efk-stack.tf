# Elasticsearch/OpenSearch + Kibana можно заменить на готовые чарты bitnami.
# Здесь пример с Elastic.
resource "helm_release" "elasticsearch" {
  name       = "elasticsearch"
  repository = "https://helm.elastic.co"
  chart      = "elasticsearch"
  version    = "8.5.1"
  namespace  = "logging"
  create_namespace = true
  values = [<<-YAML
replicas: 1
minimumMasterNodes: 1
resources:
  requests:
    cpu: "100m"
    memory: "512Mi"
  limits:
    cpu: "500m"
    memory: "2Gi"
YAML
  ]
  depends_on = [yandex_kubernetes_node_group.nodes]
}

resource "helm_release" "kibana" {
  name       = "kibana"
  repository = "https://helm.elastic.co"
  chart      = "kibana"
  version    = "8.5.1"
  namespace  = "logging"
  values = [<<-YAML
service:
  type: LoadBalancer
YAML
  ]
  depends_on = [helm_release.elasticsearch]
}

resource "helm_release" "fluent-bit" {
  name       = "fluent-bit"
  repository = "https://fluent.github.io/helm-charts"
  chart      = "fluent-bit"
  version    = "0.47.10"
  namespace  = "logging"
  values = [<<-YAML
backend:
  type: es
  es:
    host: "elasticsearch-master.logging.svc.cluster.local"
    port: 9200
    logstash_prefix: k8s
    index_key: k8s
    http_user: ""
    http_passwd: ""
parsers:
  enabled: true
YAML
  ]
  depends_on = [helm_release.elasticsearch]
}
