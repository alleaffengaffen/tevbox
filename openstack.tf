############
# Instance
############
resource "openstack_compute_instance_v2" "tevbox" {
  name                = "tevbox"
  image_id            = "a103ffce-9165-42d7-9c1f-ba0fe774fac5" # Ubuntu 22.04 LTS Jammy Jellyfish
  flavor_name         = "a1-ram2-disk20-perf1"
  security_groups     = ["default"] # Default allows egress but denies all ingress
  user_data           = data.cloudinit_config.tevbox.rendered
  stop_before_destroy = true

  network {
    name = "ext-net1"
  }
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
    })
  }
}

resource "tailscale_tailnet_key" "bootstrap" {
  ephemeral     = true
  reusable      = false
  preauthorized = true
  expiry        = 300 # 5min
  tags          = ["tag:funnel"]

  # https://github.com/tailscale/terraform-provider-tailscale/issues/144
  # lifycycle {}
}

############
# Variables
############
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
  backend "remote" {
    organization = "technat"

    workspaces {
      name = "tevbox"
    }
  }
  required_version = ">= 0.14.0"
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
