# tevbox

Spin up a development box in the cloud in no time.

## Goal

There are countless situations where you'll quickly need a fresh linux server to try something or tinker on. While for some cloud providers this can be easily achived using their consoles, for other's it's rather time-consuming to create a new instance. This project tries to solve this by automating the creation of a cloud instance using Github actions.

## Solution design

In general: a tevbox is just a dead-simple cloud instance with Ubuntu Server as OS and some development tools including [Tailscale](https://tailscale.com) and [code-server](https://github.com/coder/code-server) that provides a browser-based IDE for quick access to the cloud instance.

Currently this solution is engineered for [Hetzner](http://hetzner.de/) as cloud-provider but others might follow if there's a need for that.

The workflow for creating a new instance should look like this: I click on the [Actions](https://github.com/the-technat/tevbox/actions) for this repo, click "Create new hcloud instance", enter some details and the instance is created within minutes (faster is always appreciated), spilling out an URL where code-server is accessible and some other details about the instance.

The design makes use of the following tools / vendors:
- [Github Actions](https://docs.github.com/en/actions) to drive automation
- [Terraform](https://terraform.io) to bootstrap instances
- [Cloud-Init](https://cloudinit.readthedocs.io/en/latest/index.html) to configure instances at first boot
- [Tailscale](https://tailscale.com) to provide private network connectivity
- [Hetzner](https://hetzner.com/cloud) as cloud-provider

The workflow shouldn't make use of any other services to keep dependencies minimal.

The following requirements for the cloud instance have to be met:
- instance needs a public IPv4 and IPv6 address
- a public v4 and v6 DNS records should be created as well
- no cloud firewalls should be configured before the cloud instance
- code-server should be able to automatically expose dev services on localhost and access them on the internet using `<port>.<tevbox_name>.technat.dev` 
- cloning Github repositories is best done using `HTTPS` as code-server can automatically authenticate you against Github using device codes (but that's not preconfigured)
- `arm64` and `amd64` should be supported
- the code-server listens on `127.0.0.1:65000` 
- the code-server is exposed using [Caddy](https://caddyserver.com/) that binds to `0.0.0.0:80` and `0.0.0.0:443`

## Preconditions

For the tevbox project to work, it's important to have some static things:
- A Hetzner project with:
  - the [account-nuker](https://github.com/the-technat/account-nuker) installed
  - A cost limit + notification 
  - An API Token for the project that is allowed to read & write (token is only used within github actions)
- A DNS zone hosted on Hetzner DNS
  - A DNS API Token (token is used within Github actions and also shared with tevboxes to grab a DNS-01 challenge-based wildcard certificate)
- An S3 bucket for the Terraform state (for AWS this includes an IAM policy & role and OpenID provider for Github Actions to authenticate)
- A tailscale api key whose credentials are saved in Github action secrets
- This repo holding the source-code