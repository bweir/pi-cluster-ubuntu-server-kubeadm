# https://docs.ceph.com/en/latest/start/intro/
# https://rook.io/docs/rook/v1.7/helm-operator.html
# https://rook.io/docs/rook/v1.7/helm-ceph-cluster.html
locals {
  rook_domain      = "rook.${local.domain}"
  rook_domain_slug = "rook-${local.domain_slug}"
  rook_version     = "v1.7.4"
}

resource "kubernetes_namespace" "rook" {
  metadata {
    name = "rook-ceph"
  }
}

# https://github.com/rook/rook/tree/master/cluster/charts/rook-ceph
# https://github.com/rook/rook/blob/master/cluster/charts/rook-ceph/values.yaml
resource "helm_release" "rook" {
  name       = "rook-ceph"
  namespace  = kubernetes_namespace.rook.metadata.0.name
  repository = "https://charts.rook.io/release"
  chart      = "rook-ceph"
  version    = local.rook_version

  wait = false

  values = [yamlencode({
    enableDiscoveryDaemon = true
  })]
}

# https://github.com/rook/rook/tree/master/cluster/charts/rook-ceph-cluster
# https://github.com/rook/rook/blob/master/cluster/charts/rook-ceph-cluster/values.yaml
# https://rook.io/docs/rook/v1.7/ceph-dashboard.html#login-credentials
resource "helm_release" "rook_cluster" {
  depends_on = [
    helm_release.rook
  ]
  name       = "rook-ceph-cluster"
  namespace  = kubernetes_namespace.rook.metadata.0.name
  repository = "https://charts.rook.io/release"
  chart      = "rook-ceph-cluster"
  version    = local.rook_version

  wait = false

  values = [yamlencode({
    cephClusterSpec = {
      mon = {
        count = 3
      }
    }

    cephBlockPools = [{
      name = "ceph-blockpool"
      spec = {
        failureDomain = "host"
        replicated = {
          size = 3
        }
      }
      storageClass = {
        enabled              = true
        name                 = "ceph-block"
        isDefault            = true
        reclaimPolicy        = "Delete"
        allowVolumeExpansion = true
        parameters = {
          "imageFormat"                                           = "2"
          "imageFeatures"                                         = "layering"
          "csi.storage.k8s.io/provisioner-secret-name"            = "rook-csi-rbd-provisioner"
          "csi.storage.k8s.io/provisioner-secret-namespace"       = "rook-ceph"
          "csi.storage.k8s.io/controller-expand-secret-name"      = "rook-csi-rbd-provisioner"
          "csi.storage.k8s.io/controller-expand-secret-namespace" = "rook-ceph"
          "csi.storage.k8s.io/node-stage-secret-name"             = "rook-csi-rbd-node"
          "csi.storage.k8s.io/node-stage-secret-namespace"        = "rook-ceph"
          "csi.storage.k8s.io/fstype"                             = "ext4"
        }
      }
    }]

    cephFileSystems = [{
      name = "ceph-filesystem"
      spec = {
        metadataPool = {
          replicated = {
            size = 3
          }
        }
        dataPools = [{
          failureDomain = "host"
          replicated = {
            size = 3
          }
        }]
        metadataServer = {
          activeCount   = 1
          activeStandby = true
        }
      }
      storageClass = {
        enabled       = true
        isDefault     = false
        name          = "ceph-filesystem"
        reclaimPolicy = "Delete"
        parameters = {
          "csi.storage.k8s.io/provisioner-secret-name"            = "rook-csi-cephfs-provisioner"
          "csi.storage.k8s.io/provisioner-secret-namespace"       = "rook-ceph"
          "csi.storage.k8s.io/controller-expand-secret-name"      = "rook-csi-cephfs-provisioner"
          "csi.storage.k8s.io/controller-expand-secret-namespace" = "rook-ceph"
          "csi.storage.k8s.io/node-stage-secret-name"             = "rook-csi-cephfs-node"
          "csi.storage.k8s.io/node-stage-secret-namespace"        = "rook-ceph"
          "csi.storage.k8s.io/fstype"                             = "ext4"
        }
      }
    }]

    cephObjectStores = [{
      name = "ceph-objectstore"
      spec = {
        metadataPool = {
          failureDomain = "host"
          replicated = {
            size = 3
          }
        }
        dataPool = {
          failureDomain = "host"
          erasureCoded = {
            dataChunks   = 2
            codingChunks = 1
          }
        }
        preservePoolsOnDelete = true
        gateway = {
          port      = 80
          instances = 1
        }
        healthCheck = {
          bucket = {
            interval = "60s"
          }
        }
      }
      storageClass = {
        enabled       = true
        name          = "ceph-bucket"
        reclaimPolicy = "Delete"
        parameters = {
          region = "us-east-1"
        }
      }
    }]

    ingress = {
      dashboard = {
        annotations = {
          "kubernetes.io/ingress.class" = "nginx"
        }
        host = {
          name = local.rook_domain
        }
        tls = [{
          secretName = local.rook_domain_slug
          hosts = [
            local.rook_domain,
          ]
        }]
      }
    }
  })]
}
