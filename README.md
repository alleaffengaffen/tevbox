# tevbox

Technat's Development Box in the cloud.

## Goal

I'm tired of unpredictable development environments that are bound to your local hardware. While there are many solutions out there for this and similar problems, I prefer to setup my own. This has multiple reasons:
- performance of cloud-based IDEs is often rather poor or insufficient (for running local dev instances of things)
- control of the network stack is often not given (e.g no public IP or direct access to services exposed on your machine)
- they usually stop working when you are inactive for some time (e.g they are session-based)
- you have no idea what's all running on your IDE machine

Of course they are usually way better integrated than everything you could possibly engineer, but I still do have my own solution how I can create a fresh cloud server ready to code and tinker on.

## Solution design

In general: a tevbox is just a dead-simple VPS with Ubuntu Server as OS and some development tools including the awesome [code-server](https://github.com/coder/code-server) that provides the IDE experience in a browser. In my case I'm using [Hetzner](http://hetzner.de/) as cloud-provider as their machines offer great performance for value. 

The workflow for creating a new VM should look like this: I click on the [Actions](https://github.com/the-technat/tevbox/actions) for this repo, click "Create new box", enter some details and the box is created within minutes, spilling out an URL that opens code-server for me.

The design makes use of the following Tools:
- [Terraform](https://terraform.io) to bootstrap servers
- [Ansible](https://www.ansible.com/) to configure servers
- [Github Actions](https://docs.github.com/en/actions) to execute tools

## Tech Details

Using Github Actions as automation gives you certain benefits:
- directly integrated into Github, a click away from the source-code
- you don't need any extra login or account
- github actions can dispatch workflows manually, giving the user the option to enter some parameters

There are two main actions I will eventually merge into one:
- `deploy.yml`: Creates a new tevbox via Terraform
- `destroy.yml`: Deletes a tevbox via Terraform

For both actions to know about servers that exist, they put their Terraform state on S3. Currently Amazon S3 is used for this job, but once Hetzner releases their S3 implementation, we will switch to that. Using the name of a tevbox as identifiert for the state means, that you can delete a box by simply entering the tevbox's name and thus pointing the workflow to the right Terraform state file to use.

Terraform itself creates the VM and any necessary cloud-resources. It does however **not** configure the server. This job is done using Ansible which is way better at handling configuration. Ansible is invoked using a Terraform `remote-exec` provisioner. In order for Terraform to access the server it creates an ephemeral keypair. In case you need access to the server if ansible didn't succeed, go and grab the key from within the Terraform state.

Ansible will do the following things:
- Install commonly used tools 
- Install Caddy as reverse-proxy in front of code-server
  - Including Authentication via OpenID 
- Create the user that invoked the Github action (e.g `the-technat`)
  - Making the user sudo-capable without a password
  - Configuring SSH keys from github.com
- Install code-server and configure it for the respective user (including extensions)
- Install and run [chezmoi](https://chezmoi.io) for the created user

## Usage & Nice features

Once I have a box to use, some things nice things to know are:
- tevbox is based on Ubuntu Server (we removed multi-OS support again as was never really used and took too much effort to maintain)
- Poty 65000 is bound to the code-server, don´t use elsewhere
- Caddy binds 443/80 (to all interfaces) 
- Cloning Github repositories is best done using `HTTPS` as code-server can automatically authenticate you against Github using device codes
- Expose dev services on localhost and access them on the internet using `<port>.<tevbox_name>.technat.dev` (or whatever your zone is).
  - TLS is only supported for ports 8080, 8081, 9090, 9091, 3000 and 12000 (wildcards require custom caddy build + credentials for dns-01)
  - HTTP works for other ports as well

## Preconditions

For the tevbox project to work, it's important to have some static things:
- A Hetzner project with:
  - A cost limit + notification
  - An API Token for the project that is allowed to read & write (token is only used within github actions)
- A DNS zone hosted on Hetzner DNS
  - A DNS API Token (Note: this token is shared with all tevboxes in order for Caddy to request wildcard certificates)
- An S3 bucket for the Terraform state (for AWS this includes an IAM policy,IAM role and OpenID provider to authenticate)
- This repo holding the source-code