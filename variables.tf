variable "access_key" {
  description = "AWS Access Key ID"
  default = ""
}

variable "secret_key" {
  description = "AWS Secret Access Key"
  default = ""
}

variable "test" {
  description = "Test var"
  default = "this is a test"
}

variable "godaddy_key" {
  type        = string
  description = "GoDaddy API Key"
}

variable "godaddy_secret_key" {
  type        = string
  description = "GoDaddy API Secret Key"
}

variable "godaddy_domain" {
  type        = string
  description = "The domain name in GoDaddy where the A record will be updated"
  default = "pam4.com"
}

variable "godaddy_record_name" {
  type        = string
  description = "The name of the A record to update in the domain"
  default = "webaws"
}

variable "hetzner_dns_key" {
  type        = string
  description = "Hetzner API Secret Key"
}