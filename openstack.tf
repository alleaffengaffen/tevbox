############
# Variables
############
variable "username" {
  type        = string
  default     = "technat"
  description = "Admin user to create"
}

variable "hostname" {
  type        = string
  default     = ""
  description = "Hosname of the instance (if empty will be generated)"
}

variable "password" {
  type        = string
  sensitive   = true
  description = "Password for user created by cloud-init"
}

variable "ssh_key" {
  type        = string
  default     = ""
  description = "SSH key to configure for the admin user"
}

variable "ssh_port" {
  type        = number
  default     = 22
  description = "SSH port to configure"
}

variable "instance_flavor" {
  type        = string
  description = "Size of the instance to create"
  default     = "a1-ram2-disk20-perf1"
}

variable "tailscale_tailnet" {
  type    = string
  default = "the-technat.github"
}

# these vars are filled by GH action secrets
variable "openstack_token" {
  type      = string
  sensitive = true
}

variable "openstack_user" {
  type = string
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

output "public_ipv4" {
  value = openstack_compute_instance_v2.tevbox.access_ip_v4
}

output "public_ipv6s" {
  value = openstack_compute_instance_v2.tevbox.access_ip_v6
}

output "tailscale_addresses" {
  value = data.tailscale_device.tevbox.addresses
}

############
# Resources
############
locals {
  hostname = var.hostname != "" ? var.hostname : "tevbox-${random_integer.count.result}"
  image    = "a103ffce-9165-42d7-9c1f-ba0fe774fac5" # Ubuntu 22.04 LTS Jammy Jellyfish
  network  = "ext-net1"                             # Public NET with static assigned IPv4
  ssh_keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJov21J2pGxwKIhTNPHjEkDy90U8VJBMiAodc2svmnFC cardno:000618187880", var.ssh_key]
}
resource "openstack_compute_instance_v2" "tevbox" {
  name                = local.hostname
  image_id            = local.image
  flavor_name         = var.instance_flavor
  security_groups     = ["unrestricted"]
  user_data           = data.cloudinit_config.tevbox.rendered
  stop_before_destroy = true

  network {
    name = local.network
  }
}

resource "random_integer" "count" {
  min = 1
  max = 100
}

data "cloudinit_config" "tevbox" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "cloud-script.sh"
    content_type = "text/x-shellscript"

    content = file("${path.module}/cloud-script.sh")
  }

  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"

    content = templatefile("${path.module}/cloud-config.yaml", {
      tailnet_auth_key = tailscale_tailnet_key.bootstrap.key
      hostname         = local.hostname
      username         = var.username
      password         = var.password
      ssh_keys         = local.ssh_keys
      ssh_port         = var.ssh_port
      os_secret_id     = openstack_identity_application_credential_v3.tevbox.id
      os_secret_key    = openstack_identity_application_credential_v3.tevbox.secret
    })
  }
}

resource "tailscale_tailnet_key" "bootstrap" {
  ephemeral     = false
  reusable      = false
  preauthorized = true
  expiry        = 300 # 5min
  tags          = ["tag:funnel"]
}

resource "openstack_identity_application_credential_v3" "tevbox" {
  name         = local.hostname
  description  = "${local.hostname} identity"
  unrestricted = true                          # currently the best way to ensure everything get's deleted properly
  expires_at   = timeadd(timestamp(), "2160h") # 90 days
}


# used to dispaly IPs in output
data "tailscale_device" "tevbox" {
  name     = "${local.hostname}.crocodile-bee.ts.net"
  wait_for = "300s"

  depends_on = [openstack_compute_instance_v2.tevbox]
}

############
# Providers & requirements
############
provider "openstack" {
  application_credential_secret = var.openstack_token
  application_credential_id     = var.openstack_user # generated within the console & unrestricted
  auth_url                      = "https://api.pub1.infomaniak.cloud/identity"
  region                        = "dc3-a"
}

provider "tailscale" {
  api_key = var.tailscale_api_key # expires every 90 days
  tailnet = var.tailscale_tailnet # created by sign-up via Github
}

terraform {
  required_version = ">= 1.5.6"
  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.51.1"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "~> 0.13.9"
    }
  }
}
