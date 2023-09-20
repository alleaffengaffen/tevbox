############
# Variables
############
variable "hostname" {
  type        = string
  default     = ""
  description = "Hosname of the instance (if empty will be generated)"
}

variable "username" {
  type        = string
  default     = "technat"
  description = "Admin user to create"
}

variable "password" {
  type        = string
  sensitive   = true
  default     = ""
  description = "Password for user created by cloud-init (empty means it's disabled)"
}

variable "github_user" {
  type        = string
  description = "Username of the user that initiated the Workflow"
}

variable "ssh_port" {
  type        = number
  default     = 22
  description = "SSH port to configure"
}

variable "instance_type" {
  type        = string
  default     = "a1-ram2-disk20-perf1"
  description = "Size of the instance to create"
}

variable "flavor" {
  type        = string
  default     = "ubuntu-22.04"
  description = "OS Flavor"
}

variable "location" {
  type        = string
  default     = "hel1"
  description = "Location to deploy the server to"
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
  value = local.hostname
}

output "username" {
  value = var.username
}

output "password" {
  value = nonsensitive(var.password)
}

output "ssh_port" {
  value = var.ssh_port
}

output "instance_type" {
  value = var.instance_type
}

output "flavor" {
  value = var.flavor
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

output "tailscale_addresses" {
  value = data.tailscale_device.tevbox.addresses
}

output "code_server_url" {
  value = "https://${local.hostname}.${local.tailnet_domain}/"
}

############
# Resources
############
locals {
  tailnet_domain  = "little-cloud.ts.net"
  tailnet         = "alleaffengaffen.org.github"
  hostname        = var.hostname != "" ? var.hostname : "tevbox-${random_integer.count.result}"
  root_ssh_key_id = "rootkey" # there must be a key named rootkey in the Hcloud project to prevent Hetzner sending us mails with the root password
}
resource "hcloud_server" "tevbox" {
  name        = local.hostname
  image       = var.flavor
  server_type = var.instance_type
  location    = var.location
  keep_disk   = true
  ssh_keys    = [local.root_ssh_key_id]
  public_net {
    ipv4_enabled = true # as soon as github.com supports ipv6, this is theoretically not needed any more
    ipv6_enabled = true
  }
  user_data = <<EOT
    #cloud-config <hostname>
    packages:
    - python3
    - python3-pip
    - git
    runcmd:
      - |
        %{if var.flavor == "rocky-9"}
        sudo dnf install epel-release tar -y 
        sleep 2
        sudo dnf install ufw -y
        %{endif}
        pip3 install ansible
        git clone https://github.com/alleaffengaffen/tevbox.git /root/tevbox
        ansible-galaxy install -r /root/tevbox/requirements.yml
        rm -rf /root/tevbox
        ansible-pull -C develop --clean --purge -i localhost, \
        -U https://github.com/alleaffengaffen/tevbox.git \
        -vv tevbox.yml -e username=${var.username} \
        -e password=${var.password} -e github_user=${var.github_user} \
        -e ssh_port=${var.ssh_port} -e ts_auth_key=${tailscale_tailnet_key.bootstrap.key}
  EOT
}

resource "tailscale_tailnet_key" "bootstrap" {
  ephemeral     = false
  reusable      = false
  preauthorized = true
  expiry        = 300 # 5min
  tags          = ["tag:funnel", "tag:allow-ssh"]
}

resource "random_integer" "count" {
  min = 1
  max = 100
}

############
# Data Sources
############
data "tailscale_device" "tevbox" {
  name     = "${local.hostname}.${local.tailnet_domain}"
  wait_for = "300s"

  depends_on = [hcloud_server.tevbox]
}

############
# Providers & requirements
############
provider "hcloud" {
  token = var.hcloud_token
}

provider "tailscale" {
  api_key = var.tailscale_api_key # expires every 90 days
  tailnet = local.tailnet         # created by sign-up via Github
}

terraform {
  required_version = ">= 1.5.6"
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.42.1"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.13.9"
    }
  }
}
