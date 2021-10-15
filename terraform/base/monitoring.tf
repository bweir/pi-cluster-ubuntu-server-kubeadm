locals {
  grafana_domain      = "grafana.${local.domain}"
  grafana_domain_slug = "grafana-${local.domain_slug}"
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack
# https://github.com/grafana/helm-charts/blob/main/charts/grafana/values.yaml
resource "helm_release" "kube_prometheus" {
  name       = "kube-prometheus"
  namespace  = kubernetes_namespace.monitoring.metadata.0.name
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "18.0.6"

  wait          = false
  wait_for_jobs = false

  values = [yamlencode({
    grafana = {
      ingress = {
        enabled = true
        annotations = {
          "kubernetes.io/ingress.class" = "nginx"
        }
        hosts = [
          local.grafana_domain,
        ]
        tls = [{
          secretName = local.grafana_domain_slug
          hosts = [
            local.grafana_domain
          ]
        }]
      }
    }
  })]
}
