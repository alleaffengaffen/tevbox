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
- Terraform uses a dead-simple cloud-init script to execute `ansible-pull` to bootstrap the server at first boot
  - Ansible itself is executed as root, so by default all things will be done by root
  - Ansible receives it's dynamic variables from Terraform which has templated the `ansible-pull` command with CLI variables
  - Ansible will bootstrap the server, in case of a failure, it will abort or never run if there is a syntax error. In such a scenario the only way to get access to the server is using the rootkey defined in the project
- Once the workflow has finished, the server is up & running, you can get the details of it in the last step of the workflow

Here are some things to note when working on the machine:
- ssh keys are automatically copied from the user that executed the workflow
- the tailscale funnel is used for the code-server (e.g port 443 already blocked)
- the code-server is running for your specific user and accessible over the funnel with the password of your username
- ufw firewall is enabled, blocking all incoming traffic on the public IP except SSH -> you need to open ports you want to use

Please note that since Terraform does not track it's state, the machine is unamanged from now on. To delete it, you can run the workflow "Delete an instance" which will do some hardcoded API calls to delete the resources or you can also delete the resources manually if you want.

## Preconditions

For the tevbox project to work, it's important to have some static things:
- A Hetzner project with:
  - A cost limit + notification
  - An API Token for the project that is allowed to read & write -> since this token is shared with all servers, it would make sense to rotate it every now and then
  - An SSH key already created to prevent mails with root passwords named "rootkey"
- A Hetzner DNS API Token -> since this token is shared with all servers, it would make sense to rotate it every now and then
- A tailnet with:
  - A tailscale API key to generate tailnet keys saved as repository secret -> note that this key will expire in 90 days 
  - At least a tag named `funnel` that adds the funnel attribute to the nodes
- This repo holding the source-code

## Open Ideas

- [ ] Run GH workflow every evening checking for left-over servers and sending you a notification 
- [ ] Generate Github Identity for tevbox
