locals {
  pihole_domain      = "pihole.${local.domain}"
  pihole_domain_slug = "pihole-${local.domain_slug}"
}

resource "kubernetes_namespace" "pihole" {
  metadata {
    name = "pihole"
  }
}

resource "random_password" "pihole" {
  special = false
  length  = 16
}

# https://artifacthub.io/packages/helm/mojo2600/pihole
# https://github.com/MoJo2600/pihole-kubernetes/tree/master/charts/pihole
resource "helm_release" "pihole" {
  name       = "pihole"
  namespace  = kubernetes_namespace.pihole.metadata.0.name
  repository = "https://mojo2600.github.io/pihole-kubernetes/"
  chart      = "pihole"
  version    = "2.4.2"

  wait = false

  set_sensitive {
    name  = "adminPassword"
    value = random_password.pihole.result
  }

  # https://medium.com/@niktrix/getting-rid-of-systemd-resolved-consuming-port-53-605f0234f32f
  # https://www.linuxuprising.com/2020/07/ubuntu-how-to-free-up-port-53-used-by.html
  # https://github.com/MoJo2600/pihole-kubernetes/tree/master/charts/pihole
  # https://github.com/MoJo2600/pihole-kubernetes/blob/master/charts/pihole/values.yaml
  values = [yamlencode({
    # https://github.com/imp/dnsmasq/blob/master/dnsmasq.conf.example
    # https://www.makeuseof.com/how-to-flush-dns-cache-mac/
    dnsmasq = {
      additionalHostsEntries = [
        "${local.ingress_ip} ${local.grafana_domain}",
        "${local.ingress_ip} ${local.pihole_domain}",
        "${local.ingress_ip} ${local.rook_domain}",
      ]
    }

    replicaCount = 3

    virtualHost = local.pihole_domain

    ingress = {
      enabled = true
      annotations = {
        "kubernetes.io/ingress.class" = "nginx"
      }
      hosts = [
        local.pihole_domain,
      ]
      tls = [{
        secretName = local.pihole_domain_slug
        hosts = [
          local.pihole_domain,
        ]
      }]
    }

    maxSurge = 0

    podDnsConfig = {
      enabled = true
      policy  = "None"
      nameservers = concat([
        "127.0.0.1",
        var.dns_1,
        var.dns_2,
      ])
    }

    persistentVolumeClaim = {
      enabled = true
      accessModes = [
        "ReadWriteMany",
      ]
      storageClass = "ceph-filesystem"
    }

    affinity = {
      podAntiAffinity = {
        requiredDuringSchedulingIgnoredDuringExecution = [
          {
            labelSelector = {
              matchLabels = {
                app     = "pihole"
                release = "pihole"
              }
            }
            topologyKey = "kubernetes.io/hostname"
          }
        ]
      }
    }

    serviceDhcp = {
      enabled = false
    }

    serviceWeb = {
      type = "ClusterIP"
    }

    serviceDns = {
      type           = "LoadBalancer"
      loadBalancerIP = local.dns_ip

      annotations = {
        # https://metallb.universe.tf/usage/#ip-address-sharing
        # https://github.com/kubernetes/kubernetes/issues/23880#issuecomment-648922653
        "metallb.universe.tf/allow-shared-ip" = "pihole-dns"
      }
    }

    monitoring = {
      sidecar = {
        enabled = true
      }
    }
  })]
}
