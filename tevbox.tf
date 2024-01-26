############
# Resources
############
resource "hcloud_server" "tevbox" {
  name        = var.hostname
  image       = var.image
  server_type = var.type
  location    = var.location
  keep_disk   = true
  ssh_keys    = ["rootkey"] # there must be a key named rootkey in the Hcloud project to prevent Hetzner sending us mails with the root password
  public_net {
    ipv4_enabled = true # as soon as github.com supports ipv6, this is theoretically not needed any more
    ipv6_enabled = true
  }
  user_data = <<EOT
    #cloud-config ${var.hostname}
    packages:
    - python3
    - python3-pip
    - git
    runcmd:
      - |
        pip3 install ansible
        ansible-galaxy collection install community.general

        ansible-pull -C develop --clean --purge -i localhost, \
        -U https://github.com/the-technat/tevbox.git \
        -vv tevbox.yml -e username=${var.username} \
        -e password=${var.password} -e ssh_port=${var.ssh_port} \
        -e fqdn=${var.hostname}.${local.zone}
  EOT
}

resource "hetznerdns_record" "tevbox_v4" {
    zone_id = data.hetznerdns_zone.main.id
    name = var.hostname
    value = hcloud_server.tevbox.ipv4_address
    type = "A"
    ttl= 60
}

resource "hetznerdns_record" "tevbox_v4_proxy_wildcard" {
    zone_id = data.hetznerdns_zone.main.id
    name = "*.${var.hostname}"
    value = hcloud_server.tevbox.ipv4_address
    type = "A"
    ttl= 60
}

resource "hetznerdns_record" "tevbox_v6" {
    zone_id = data.hetznerdns_zone.main.id
    name = var.hostname
    value = hcloud_server.tevbox.ipv6_address
    type = "AAAA"
    ttl= 60
}

resource "hetznerdns_record" "tevbox_v6_proxy_wildcard" {
    zone_id = data.hetznerdns_zone.main.id
    name = "*.${var.hostname}"
    value = hcloud_server.tevbox.ipv6_address
    type = "AAAA"
    ttl= 60
}

locals {
  zone = "technat.dev"
}

############
# Data Sources
############
data "hetznerdns_zone" "main" {
    name = local.zone
}

############
# Variables
############
variable "hostname" {
  type        = string
}

variable "username" {
  type        = string
}

variable "password" {
  type        = string
  sensitive   = true
}

variable "ssh_port" {
  type        = number
}

variable "type" {
  type        = string
}

variable "image" {
  type        = string
}

variable "location" {
  type        = string
}

# these vars are filled by GH action secrets
variable "hcloud_token" {
  type      = string
  sensitive = true
}
variable "hetzner_dns_token" {
  type = string
  sensitive = true
}

############
# Outputs
############
output "hostname" {
  value = var.hostname
}

output "username" {
  value = var.username
}

output "ssh_port" {
  value = var.ssh_port
}

output "type" {
  value = var.type
}

output "flavor" {
  value = var.image
}

output "location" {
  value = var.location
}

output "public_ipv4" {
  value = hcloud_server.tevbox.ipv4_address
}

output "public_ipv6" {
  value = hcloud_server.tevbox.ipv6_address
}

output "code_server_url" {
  value = "https://${var.hostname}.${local.zone}/"
}

############
# Providers & requirements
############
provider "hcloud" {
  token = var.hcloud_token
}

provider "hetznerdns" {
  apitoken = var.hetzner_dns_token 
}

terraform {
  backend "s3" {} # github actions will configure the rest
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
    }
    hetznerdns = {
      source = "timohirt/hetznerdns"
    }
  }
}
