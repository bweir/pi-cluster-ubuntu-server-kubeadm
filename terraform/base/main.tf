resource "helm_release" "cilium" {
  name       = "cilium"
  namespace  = "kube-system"
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  version    = "1.10.3"

  wait = false

  values = [yamlencode({
    operator = {
      resources = {
        requests = {
          cpu    = "10m"
          memory = "20Mi"
        }
      }
    }

    resources = {
      requests = {
        cpu    = "50m"
        memory = "160Mi"
      }
    }
  })]
}
