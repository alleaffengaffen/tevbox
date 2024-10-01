############
# Resources
############
resource "hcloud_server" "tevbox" {
  name        = var.hostname
  image       = "ubuntu-24.04"
  server_type = var.type
  location    = var.location
  keep_disk   = true
  public_net {
    ipv4_enabled = true
    ipv6_enabled = true
  }
  user_data = data.cloudinit_config.tevbox.rendered
}

data "cloudinit_config" "tevbox" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "hcloud.sh"
    content_type = "text/x-shellscript"

    content = templatefile("${path.module}/hcloud.sh", {
      tailscale_auth_key = nonsensitive(tailscale_tailnet_key.tevbox.key)
      username           = var.username
      password           = var.password
      fqdn               = local.fqdn
      hetzner_dns_token  = nonsensitive(var.hetzner_dns_token)
    })
  }

}
resource "hetznerdns_record" "tevbox_v4" {
  zone_id = data.hetznerdns_zone.main.id
  name    = var.hostname
  value   = hcloud_server.tevbox.ipv4_address
  type    = "A"
  ttl     = 60
}

resource "hetznerdns_record" "tevbox_v4_wildcard" {
  zone_id = data.hetznerdns_zone.main.id
  name    = "*.${var.hostname}"
  value   = hcloud_server.tevbox.ipv4_address
  type    = "A"
  ttl     = 60
}

resource "hetznerdns_record" "tevbox_v6" {
  zone_id = data.hetznerdns_zone.main.id
  name    = var.hostname
  value   = hcloud_server.tevbox.ipv6_address
  type    = "AAAA"
  ttl     = 60
}

resource "hetznerdns_record" "tevbox_v6_wildcard" {
  zone_id = data.hetznerdns_zone.main.id
  name    = "*.${var.hostname}"
  value   = hcloud_server.tevbox.ipv6_address
  type    = "AAAA"
  ttl     = 60
}

resource "hcloud_rdns" "tevbox_v4" {
  server_id  = hcloud_server.tevbox.id
  ip_address = hcloud_server.tevbox.ipv4_address
  dns_ptr    = local.fqdn
}

resource "tailscale_tailnet_key" "tevbox" {
  reusable      = false
  ephemeral     = false
  preauthorized = true
  expiry        = 3600
  description   = "${var.hostname} tevbox"
  tags          = ["acl-server"]
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
  zone    = "technat.dev"
  tailnet = "the-technat.github"
  fqdn    = "${var.hostname}.${local.zone}"
}

variable "hostname" {
  type = string
}

variable "password" {
  type      = string
  sensitive = true
}

variable "revision" {
  type = string
}

variable "username" {
  type = string
}

variable "type" {
  type = string
}

variable "location" {
  type = string
}

# these vars are filled by GH action secrets
variable "hcloud_token" {
  type      = string
  sensitive = true
}
variable "hetzner_dns_token" {
  type      = string
  sensitive = true
}
variable "tailscale_api_key" {
  type      = string
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

provider "tailscale" {
  api_key = var.tailscale_api_key
  tailnet = local.tailnet
}

terraform {
  backend "s3" {} # github actions will configure the rest
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.48.1"
    }
    hetznerdns = {
      source  = "timohirt/hetznerdns"
      version = "2.2.0"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "0.17.1"
    }
  }
}
