variable "dns_1" {
  type = string
}

variable "dns_2" {
  type = string
}

variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}
