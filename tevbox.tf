############
# Resources
############
resource "hcloud_server" "tevbox" {
  name         = var.hostname
  image        = "ubuntu-22.04"
  server_type  = var.type
  location     = var.location
  keep_disk    = true
  firewall_ids = [hcloud_firewall.tevbox.id]
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
    filename     = "tevbox.sh"
    content_type = "text/x-shellscript"

    content = templatefile("${path.module}/tevbox.sh", {
      enable_ssh        = var.enable_ssh
      username          = var.username
      password          = var.password
      fqdn              = local.fqdn
      hetzner_dns_token = nonsensitive(var.hetzner_dns_token)
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

resource "hcloud_firewall" "ssh" {
  count = var.enable_ssh ? 1 : 0
  name  = "${var.hostname}-ssh"
  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}
resource "hcloud_firewall_attachment" "ssh" {
  count       = var.enable_ssh ? 1 : 0
  firewall_id = hcloud_firewall.ssh[0].id
  server_ids  = [hcloud_server.tevbox.id]
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

variable "enable_ssh" {
  type = bool
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
      version = "1.47.0"
    }
    hetznerdns = {
      source  = "timohirt/hetznerdns"
      version = "2.2.0"
    }
  }
}
