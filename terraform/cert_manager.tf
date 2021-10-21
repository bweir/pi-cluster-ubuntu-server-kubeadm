locals {
  cloudflare_secret_name = "cloudflare-api-token" # pragma: allowlist secret
  cloudflare_secret_key  = "cloudflare-api-token" # pragma: allowlist secret
}

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
# https://cert-manager.io/docs/configuration/acme/dns01/cloudflare/
resource "kubernetes_secret" "cloudflare_api_token" {
  metadata {
    name      = local.cloudflare_secret_name
    namespace = kubernetes_namespace.cert_manager.metadata.0.name
  }
  data = {
    "${local.cloudflare_secret_key}" = var.cloudflare_api_token
  }
  type = "Opaque"
}

resource "kubernetes_manifest" "staging_issuer" {
  depends_on = [
    helm_release.cert_manager,
  ]

  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-staging"
    }
    spec = {
      acme = {
        email  = "contact@lamestation.com"
        server = "https://acme-staging-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "letsencrypt-staging-private-key"
        }
        solvers = [{
          dns01 = {
            cloudflare = {
              apiTokenSecretRef = {
                name = local.cloudflare_secret_name
                key  = local.cloudflare_secret_key
              }
            }
          }
        }]
      }
    }
  }
}

resource "kubernetes_manifest" "production_issuer" {
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-production"
    }
    spec = {
      acme = {
        email  = "contact@lamestation.com"
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "letsencrypt-production-private-key"
        }
        solvers = [{
          dns01 = {
            cloudflare = {
              apiTokenSecretRef = {
                name = local.cloudflare_secret_name
                key  = local.cloudflare_secret_key
              }
            }
          }
        }]
      }
    }
  }
}
