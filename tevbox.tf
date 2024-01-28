############
# Resources
############
resource "hcloud_server" "tevbox" {
  name        = var.hostname
  image       = "ubuntu-22.04"
  server_type = var.type
  location    = var.location
  keep_disk   = true
  firewall_ids = [hcloud_firewall.tevbox.id]
  public_net {
    ipv4_enabled = true # as soon as github.com supports ipv6, this is theoretically not needed any more
    ipv6_enabled = true
  }
  user_data = <<EOT
    #cloud-config ${var.hostname}
    packages:
    - ansible # note: other OSes might not contain an ansible package and they might also not contain community.general collection out of the box
    runcmd:
      - |
        ansible-pull -C develop --clean --purge -i localhost, \
        -U https://github.com/the-technat/tevbox.git \
        -vv tevbox.yml -e username=${var.username} \ 
        -e fqdn=${local.fqdn} -e dns_token="${var.hetzner_dns_token}"
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

resource "hcloud_rdns" "tevbox" {
  server_id  = hcloud_server.tevbox.id
  ip_address = hcloud_server.tevbox.ipv4_address
  dns_ptr    = local.fqdn
}

resource "hcloud_firewall" "tevbox" {
  name = var.hostname
  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "80"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

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
locals {
  zone = "technat.dev"
  fqdn = "${var.hostname}.${local.zone}"
}

variable "hostname" {
  type        = string
}

variable "username" {
  type        = string
}

variable "type" {
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

output "type" {
  value = var.type
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
      version = "1.45.0"
    }
    hetznerdns = {
      source = "timohirt/hetznerdns"
      version = "2.2.0"
    }
  }
}
