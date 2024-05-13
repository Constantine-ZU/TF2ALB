variable "access_key" {
  description = "AWS Access Key ID"
  default = ""
}

variable "secret_key" {
  description = "AWS Secret Access Key"
  default = ""
}

variable "hetzner_dns_key" {
  type        = string
  description = "Hetzner API Secret Key"
   default = "0000"
}