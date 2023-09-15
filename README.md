# tevbox

Technat's Development Box in the cloud

## Goal

From time to time we need a development environment on the go. While there are many solutions out there, I prefer to setup my own. This has multiple reasons:
- performance of cloud-based IDEs is often rather poor or insufficient (in my personal experience)
- control of the network stack is often not given (e.g no public IP or direct access to the machines NIC which is sometimes nice to have)
- they usually stop working when you are inactive for some time (e.g they are session-based)

So this repo provides a solution how you can quickly create a fresh cloud server ready for you to code and tinker on.

## Solution design

In general: a tevbox is just a dead-simple VPS with a mainstream Linux Distro and some development tools. In my case I'm using [Hetzner](http://hetzner.de/) for this job as their machines are very affordable.

The workflow for creating a new VM is simple
- Head over to the Actions tab of this repository and manually dispatch the workflow "Create new instance".
  - You are asked certain parameters which are sometimes mandatory and sometimes just to allow for customization
- The workflow will pass these variables 1:1 to [Terraform](https://www.terraform.io/) which in turn creates the server
  - Terraform is stateless, so we fire and forget which makes the machine unmanaged afterwards
- Terraform uses cloud-init to bootstrap the server at first boot
  - Cloud-init executes everything as root, so your shell customization and other things have to be done manually
- Once the workflow has finished, the server is up & running, you can get the details of it in the last step of the workflow

Please note that since Terraform does not track it's state, the machine is unamanged from now on. You must manually delete / stop / restart it from the Hetzner Console. For some extra convenience there's a commaned called `destroy-machine` that will terminate the instance once executed.

## Preconditions

For the tevbox project to work, it's important to have some static things:
- A Hetzner project with:
  - An API Token for the project that is allowed to read & write
  - An SSH key already created to prevent mails with root passwords named "rootkey"
- A Hetzner DNS API Token 
- A tailnet with:
  - A tailscale API key to generate tailnet keys saved as repository secret -> note that this key will expire in 90 days 
  - At least a tag named `funnel` that adds the funnel attribute to the nodes
- This repo holding the source-code

**Note:** The API token for Hcloud is shared across all created machines in order to easily destroy them if needed.

## Open Ideas

- [ ] Fix HCLOUD_TOKEN not beeing propagated correctly
- [ ] Run GH workflow every evening checking for left-over servers and sending you a notification 
- [ ] Make DNS record optional (since you have to cleanup it manually anyway) or check if Terraform can override the already existing record 
