# tevbox

Technat's Development Box in the cloud

## Goal

From time to time we need a development environment on the go. While there are many solutions out there, I prefer to setup my own. This has multiple reasons:
- performance of cloud-based IDEs is often rather poor or insufficient (in my personal experience)
- control of the network stack is often not given (e.g no public IP or direct access to the machines NIC which is sometimes nice to have)
- they usually stop working when you are inactive for some time (e.g they are session-based)

So this repo provides a solution how you can quickly create a fresh cloud server ready for you to code and tinker on.

## Solution design

In general: a tevbox is just a dead-simple VPS with a mainstream Linux Distro and some development tools as well as the famous [code-server](https://github.com/coder/code-server). In my case I'm using [Hetzner](http://hetzner.de/) for this job as their machines are very affordable.

The workflow for creating a new VM is as follows:
- Head over to the Actions tab of this repository and manually dispatch the workflow "Create new instance".
  - You are asked certain parameters which are sometimes mandatory and sometimes just to allow for customization
  - Some settings are also read from your Github user (since the workflow knows who initiated it)
- The workflow will pass these variables 1:1 to [Terraform](https://www.terraform.io/) which in turn creates the server
  - Terraform is stateless, so we fire and forget which makes the machine unmanaged afterwards (e.g state is deleted after every run)
  - Terraform uses a dead-simple cloud-init script to execute `ansible-pull` to bootstrap the server at first boot
- Ansible itself is executed as root (due to cloud-init), so by default all things will be done by root
  - Ansible receives it's dynamic variables from Terraform which has templated the `ansible-pull` command with CLI variables -> they will always override any other variables set within ansible
  - Ansible will bootstrap the server, in case of a failure, it will abort or never run if there is a syntax error. In such a scenario the only way to get access to the server is using the `rootkey` defined in the project
- Once the workflow has finished, the server is up & running. You can get the details of the server in the `Terraform Apply` step's logs
- To delete the machine you can simply trigger the workflow "Delete an instance" and enter the name of your instance

Here are some things to note when working on the machine:
- ssh keys are automatically copied from your Github user
- the machines has joined my tailnet called 'alleaffengaffen.org.github' and thus has access to other machines in this VPN
- the code-server is running for your specific user and accessible over the funnel with the password of your username
- the tailscale [funnel]() on port 443 is already blocked due to the code-server -> either expose on the domain/public IP or use port 8443/10000 on the funnel
- ufw firewall is enabled, blocking all incoming traffic on the public IP except SSH -> you need to open ports you want to use
- authentication against Github is done automatically if you are using the code-server in a browser, all you need is a Github session in the same browser

## Preconditions

For the tevbox project to work, it's important to have some static things:
- A Hetzner project with:
  - A cost limit + notification
  - An API Token for the project that is allowed to read & write 
  - An SSH key named `rootkey` which allows emergency access to the root user (if ansible doesn't reconfiure ssh) + prevents Hetzner from sending a mail with the generated root password
- A Hetzner DNS API Token 
- A tailnet with:
  - A tailscale API key to generate tailnet keys saved as repository secret -> note that this key will expire in 90 days 
  - At least a tag named `funnel` that adds the funnel attribute to the nodes
- This repo holding the source-code

## Open Ideas

- [ ] Run GH workflow every evening checking for left-over servers and sending you a notification 
