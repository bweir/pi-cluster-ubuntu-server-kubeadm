resource "kubernetes_namespace" "metallb" {
  metadata {
    name = "metallb"
  }
}

# https://artifacthub.io/packages/helm/metallb/metallb
resource "helm_release" "metallb" {
  name       = "metallb"
  namespace  = kubernetes_namespace.metallb.metadata.0.name
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  version    = "~> 0.10.2"

  wait = false

  values = [yamlencode({
    configInline = {
      "address-pools" = [{
        name     = "default"
        protocol = "layer2"
        addresses = [
          "192.168.1.5-192.168.1.15"
        ]
      }]
    }
  })]
}
