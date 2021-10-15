locals {
  domain      = "bweir.dev"
  domain_slug = replace(local.domain, ".", "-")

  dns_ip     = "192.168.1.5"
  ingress_ip = "192.168.1.6"
}
