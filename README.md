# tevbox

Technat's Development Box in the cloud.

## Goal

I'm tired of unpredictable development environments that are bound to your local hardware. While there are many solutions out there for this and similar problems, I prefer to setup my own. This has multiple reasons:
- performance of container-based IDEs is often rather poor or insufficient (for running local dev instances of things)
- container based IDEs are not persistent, which is sometimes nice to have (e.g if you spin uf local Kubernetes clusters and want them to run a couple of hours)
- control of the network stack is often not given (e.g no public IP or direct access to services exposed on your machine)
- they usually stop working when you are inactive for some time (e.g they are session-based, not running in the background)
- you have no idea what's all running on your IDE machine nor could one call the image minimal

Of course the solutions I'm talking about are usually way better integrated than everything you could possibly engineer yourself, but I still do have my own solution how I can create a fresh cloud server ready to code and tinker on.

## Solution design

In general: a tevbox is just a dead-simple VPS with Ubuntu Server as OS and some development tools including the awesome [code-server](https://github.com/coder/code-server) that provides the IDE experience in a browser. In my case I'm using [Hetzner](http://hetzner.de/) as cloud-provider as their machines offer great performance for value. 

The workflow for creating a new VM should look like this: I click on the [Actions](https://github.com/the-technat/tevbox/actions) for this repo, click "Create new box", enter some details and the box is created within minutes (faster is always appreciated), spilling out an URL that opens code-server for me.

The design makes use of the following Tools:
- [Github Actions](https://docs.github.com/en/actions) to execute both tools
- [Terraform](https://terraform.io) to bootstrap servers
- [Cloud-Init](https://cloudinit.readthedocs.io/en/latest/index.html) to configure servers at first boot

Apart from these tools, I also use Github for the code and actions and Hetzner for the servers. The workflow shouldn't make use of any other services to keep dependencies minimal.

## Tech Details

Using Github Actions as automation gives you certain benefits:
- directly integrated into Github, a click away from the source-code
- you don't need any extra login or account
- github actions can dispatch workflows manually, giving the user the option to enter some parameters

There are two main actions I will eventually merge into one:
- `deploy.yml`: Creates a new tevbox via Terraform
- `destroy.yml`: Deletes an existing tevbox via Terraform

For both actions to know about servers that exist, they put their Terraform state on S3. Currently Amazon S3 is used for this job, but once Hetzner releases their S3 implementation, we will switch to that. Using the name of a tevbox as identifier for the state means, that you can delete a box by simply entering the tevbox's name and thus pointing the workflow to the right Terraform state file to use.

Terraform itself creates the VM and any necessary cloud-resources. Cloud-init is responsible for configuring the server at first boot. This is done using a simple shell script and some templating. Initially this project used Ansible for that job in pull-mode, but since that was too slow and without any benefits for a one-shot configuration we switched to something simpler.

Once I have a box to use, some things nice things to know are:
- tevbox is based on Ubuntu Server (we removed multi-OS support again as it was never really used and took too much effort to maintain)
- tevbox is multi-arch compatible, `arm64` and `amd64` are available (defined by the used instance type)
- the code-server listens on `127.0.0.1:65000` 
- the code-server is exposed using [Caddy](https://caddyserver.com/) that binds to `0.0.0.0:80` and `0.0.0.0:443`
- Cloning Github repositories is best done using `HTTPS` as code-server can automatically authenticate you against Github using device codes
- Expose dev services on localhost and access them on the internet using `<port>.<tevbox_name>.technat.dev` (or whatever your zone is).

In case of a failure in the cloud-init script, the only way to get access to the server is using the Console in the portal. Use the root user and the password sent to you via mail (if you haven´t deleted that mail already).

## Preconditions

For the tevbox project to work, it's important to have some static things:
- A Hetzner project with:
  - the [account-nuker](https://github.com/the-technat/account-nuker) installed
  - A cost limit + notification 
  - An API Token for the project that is allowed to read & write (token is only used within github actions)
- A DNS zone hosted on Hetzner DNS
  - A DNS API Token (token is used within github actions and also shared with tevboxes to grab a DNS-01 challenge-based wildcard certificate)
- An S3 bucket for the Terraform state (for AWS this includes an IAM policy & role and OpenID provider for Github Actions to authenticate)
- This repo holding the source-code