output "services" {
  value = {
    dns     = local.dns_ip
    ingress = local.ingress_ip
  }
}
