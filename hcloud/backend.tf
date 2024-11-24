terraform {
  backend "s3" {} # github actions will configure the rest
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.49.0"
    }
    hetznerdns = {
      source  = "timohirt/hetznerdns"
      version = "2.2.0"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "0.17.2"
    }
  }
}
