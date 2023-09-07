############
# Instance
############
locals {
  hostname = "tevbox-${random_integer.count.result}"
}
resource "openstack_compute_instance_v2" "tevbox" {
  name                = local.hostname
  image_id            = "a103ffce-9165-42d7-9c1f-ba0fe774fac5" # Ubuntu 22.04 LTS Jammy Jellyfish
  flavor_name         = var.instance_flavor
  security_groups     = ["unrestricted"]
  user_data           = data.cloudinit_config.tevbox.rendered
  stop_before_destroy = true

  network {
    name = "ext-net1"
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
      user_password    = var.user_password
      hostname         = local.hostname
      os_secret_id     = openstack_identity_application_credential_v3.tevbox.id
      os_secret_key    = openstack_identity_application_credential_v3.tevbox.secret
    })
  }
}

resource "openstack_identity_application_credential_v3" "tevbox" {
  name        = local.hostname
  description = "${local.hostname} identity"
  expires_at  = timeadd(timestamp(), "2160h") # 90 days

  # grant permissions to delete compute related things
  access_rules {
    path    = "/v2.1/servers/**"
    service = "compute"
    method  = "DELETE"
  }

  # grant permissions to delete identity related things
  access_rules {
    path    = "/v3/users/**"
    service = "identity"
    method  = "DELETE"
  }
}


resource "tailscale_tailnet_key" "bootstrap" {
  ephemeral     = false
  reusable      = false
  preauthorized = true
  expiry        = 300 # 5min
  tags          = ["tag:funnel"]
}

data "tailscale_device" "tevbox" {
  name     = "${local.hostname}.crocodile-bee.ts.net"
  wait_for = "300s"

  depends_on = [openstack_compute_instance_v2.tevbox]
}

############
# Outputs
############
output "public_ipv4" {
  value = openstack_compute_instance_v2.tevbox.access_ip_v4
}

output "public_ipv6" {
  value = openstack_compute_instance_v2.tevbox.access_ip_v6
}

output "hostname" {
  value = local.hostname
}

output "tailscale_addresses" {
  value = data.tailscale_device.tevbox.addresses
}

output "username" {
  value = "technat"
}

output "password" {
  value = nonsensitive(var.user_password)
}

############
# Variables
############
variable "user_password" {
  type        = string
  sensitive   = true
  description = "Password for user created by cloud-init"
}

variable "instance_flavor" {
  type        = string
  description = "Size of the instance to create"
  default     = "a1-ram2-disk20-perf1"
}

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

variable "tailscale_tailnet" {
  type    = string
  default = "the-technat.github"
}

############
# TF config
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
