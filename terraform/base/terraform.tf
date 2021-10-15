terraform {
  backend "remote" {
    organization = "bweir"
    workspaces {
      name = "homelab-base"
    }
  }
}
