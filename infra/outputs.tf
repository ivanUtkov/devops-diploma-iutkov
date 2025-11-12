output "ingress_nginx_lb_hostname" {
  value = try(
    kubernetes_service.ingress_lb.status[0].load_balancer[0].ingress[0].hostname,
    "use kubectl get svc -n ingress-nginx"
  )
  description = "LoadBalancer hostname for ingress-nginx (если доступно)"
}
