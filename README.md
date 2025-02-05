# tevbox

Spin up a development box in the cloud in no time.

## !! Archived !! 

I never really got to the point where I was using this project enough to justify the effort it takes to ensure the automation is up-to-date and works out of the box. I'm probably better using Cloud Provider's web console whenever I need something quick and easy.

## Goal

There are countless situations where you'll quickly need a fresh linux box to try something or tinker on. While for some cloud providers this can be easily achived using their consoles, for other's it's rather time-consuming to create a new box. This project tries to solve this by automating the creation of a box using Github actions.

## Solution design

In general: a tevbox is just a dead-simple cloud instance with Ubuntu Server as OS and some development tools including [tailscale](https://tailscale.com) and [code-server](https://github.com/coder/code-server) that provides a browser-based IDE for quick access to the cloud instance.

Currently this solution is engineered for [Hetzner](http://hetzner.de/) as cloud-provider but others might follow if there's a need for that.

The workflow for creating a new box should look like this: I click on the [actions](https://github.com/the-technat/tevbox/actions) for this repo, click "Hcloud box", enter some details and the box is created within minutes (faster is always appreciated), spilling out an URL where code-server is accessible and some other details about the box.

The design makes use of the following tools / vendors:
- [Github Actions](https://docs.github.com/en/actions) to drive automation
- [Terraform](https://terraform.io) to bootstrap instances
- [Cloud-Init](https://cloudinit.readthedocs.io/en/latest/index.html) to configure instances at first boot
- [Tailscale](https://tailscale.com) to provide private network connectivity
- [Hetzner](https://hetzner.com/cloud) as cloud-provider

The following requirements for the cloud instance have to be met:
- must be Ubuntu server
- needs a public IPv4 and IPv6 address
- needs a public resolvable DNS A and AAAA record (optionally also PTR record)
- mustn't have any cloud-provider firewalls configured (no security groups or the like)

The following features will be supported using the box:
- is tailnet joined, ssh-enabled
- code-server can automatically forward traffic to dev services exposed on localhost, using the following URL pattern: `<port>.<tevbox_name>.technat.dev` 
- cloning Github repositories is best done using `HTTPS` as code-server can automatically authenticate you against Github using device codes (has to be configured on first use)

## Limitations

I'm using a S3 bucket for storing Terraform state. Now since Hetzner bills you for empty buckets, the bucket is always created when a new box is needed. This means that once the box is deleted, the same hostname can't be used for 14 days (reusing bucket names on Hcloud is only allowed after 14 days).

## Preconditions

For the tevbox project to work, it's important to have some static things:
- A Hetzner project with:
  - the [account-nuker](https://github.com/the-technat/account-nuker) installed 
  - A cost limit + notification 
  - An API token for the project that is allowed to read & write (token is only used within github actions) 
  - An S3 credential 
- A DNS zone hosted on Hetzner DNS (`technat.dev` for me) 
  - A DNS API Token (token is used within Github actions and also shared with tevboxes to grab a DNS-01 challenge-based wildcard certificate) 
- A tailscale api key 
- This repo
