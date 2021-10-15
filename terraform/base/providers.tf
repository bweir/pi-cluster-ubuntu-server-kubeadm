provider "kubernetes" {
  experiments {
    manifest_resource = true
  }
}

provider "helm" {}
