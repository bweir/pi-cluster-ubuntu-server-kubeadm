resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

# https://artifacthub.io/packages/helm/cert-manager/cert-manager
# https://cert-manager.io/docs/configuration/selfsigned/
# https://github.com/jetstack/cert-manager/tree/master/deploy/charts/cert-manager
#
# If the installation fails, to try again, first:
#
# helm uninstall cert-manager
# k delete sa cert-manager-startupapicheck
# k delete job cert-manager-startupapicheck
# k delete role cert-manager-startupapicheck:create-cert
# k delete rolebindings.rbac.authorization.k8s.io cert-manager-startupapicheck:create-cert
#
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  namespace  = kubernetes_namespace.cert_manager.metadata.0.name
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "~> 1.5.3"

  wait          = false
  wait_for_jobs = false

  values = [yamlencode({
    installCRDs = true

    resources = {
      limits = {
        cpu    = "1000m"
        memory = "150Mi"
      }
      requests = {
        cpu    = "10m"
        memory = "100Mi"
      }
    }
  })]
}

# https://github.com/hashicorp/terraform-provider-kubernetes/issues/1352
# https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest
