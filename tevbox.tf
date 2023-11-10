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
        ansible-galaxy install collection community.general

        ansible-pull -C develop --clean --purge -i localhost, \
        -U https://github.com/alleaffengaffen/tevbox.git \
        -vv tevbox.yml -e username=${var.username} \
        -e password=${var.password} -e ssh_port=${var.ssh_port} \
        -e ts_auth_key=${tailscale_tailnet_key.bootstrap.key}
  EOT
}

resource "tailscale_tailnet_key" "bootstrap" {
  ephemeral     = false
  reusable      = false
  preauthorized = true
  expiry        = 300 # 5min
  tags          = ["tag:feature-funnel"]
}

############
# Data Sources
############
data "tailscale_device" "tevbox" {
  name     = "${var.hostname}.${var.tailnet_domain}"
  wait_for = "300s"

  depends_on = [hcloud_server.tevbox]
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

variable "tailnet" {
  type = string
}

variable "tailnet_domain" {
  type = string
}

# these vars are filled by GH action secrets
variable "hcloud_token" {
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

output "tailnet" {
 value = var.tailnet
}

output "public_ipv4" {
  value = hcloud_server.tevbox.ipv4_address
}

output "public_ipv6" {
  value = hcloud_server.tevbox.ipv6_address
}

output "tailscale_addresses" {
  value = data.tailscale_device.tevbox.addresses
}

output "code_server_url" {
  value = "https://${var.hostname}.${var.tailnet_domain}/"
}

############
# Providers & requirements
############
provider "hcloud" {
  token = var.hcloud_token
}

provider "tailscale" {
  api_key = var.tailscale_api_key # expires every 90 days
  tailnet = var.tailnet         # created by sign-up via Github
}

terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
    }
    tailscale = {
      source  = "tailscale/tailscale"
    }
  }
}
