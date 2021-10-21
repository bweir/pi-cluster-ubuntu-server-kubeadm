resource "kubernetes_namespace" "ingress" {
  metadata {
    name = "ingress"
  }
}

# https://artifacthub.io/packages/helm/ingress-nginx/ingress-nginx
# https://github.com/kubernetes/ingress-nginx/blob/main/charts/ingress-nginx/values.yaml
# https://www.digitalocean.com/community/tutorials/how-to-set-up-an-nginx-ingress-on-digitalocean-kubernetes-using-helm
resource "helm_release" "ingress_nginx" {
  name       = "ingress-nginx"
  namespace  = kubernetes_namespace.ingress.metadata.0.name
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  version    = "~> 4.0.5"

  wait = false

  values = [yamlencode({
    controller = {
      replicaCount = 1

      resources = {
        requests = {
          cpu    = "100m"
          memory = "100Mi"
        }
      }

      service = {
        loadBalancerIP = local.ingress_ip
      }

      affinity = {
        podAntiAffinity = {
          requiredDuringSchedulingIgnoredDuringExecution = [
            {
              labelSelector = {
                matchLabels = {
                  "app.kubernetes.io/component" = "controller"
                  "app.kubernetes.io/instance"  = "ingress-nginx"
                  "app.kubernetes.io/name"      = "ingress-nginx"
                }
              }
              topologyKey = "kubernetes.io/hostname"
            }
          ]
        }
      }
    }
  })]
}
