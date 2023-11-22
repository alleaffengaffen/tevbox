# tevbox

Technat's Development Box in the cloud

## Goal

From time to time we need a development environment on the go. While there are many solutions out there for this exact problem, I prefer to setup my own. This has multiple reasons:
- performance of cloud-based IDEs is often rather poor or insufficient (in my personal experience)
- control of the network stack is often not given (e.g no public IP or direct access to the machines NIC which is sometimes nice to have)
- they usually stop working when you are inactive for some time (e.g they are session-based)
- you have no idea what's all running on your IDE machine

So this repo provides a solution how you can quickly create a fresh cloud server ready for you to code and tinker on.

## Solution design

In general: a tevbox is just a dead-simple VPS with a mainstream Linux Distro and some development tools as well as the famous [code-server](https://github.com/coder/code-server). All other tools you need to develop are most likely also browser-based so this means you can code from wherever you want. In my case I'm using [Hetzner](http://hetzner.de/) for this job as their machines are very affordable. But it could be anything, doesn't even need to be public, due to the awesome work of [Tailscale](https://tailscale.com).

The workflow for creating a new VM is as follows:
- Head over to the Actions tab of this repository and manually dispatch the workflow "Create new box".
  - You are asked certain parameters which are sometimes mandatory and sometimes just to allow for customization in special situations
  - Some settings are also read from your Github user (since the workflow knows who initiated it)
- The workflow will pass these variables 1:1 to [Terraform](https://www.terraform.io/) which in turn creates the server
  - Terraform stores a new state and variable file for every box on AWS S3, so that the instance can later be destroyed by only specifing the hostname
  - Terraform uses a dead-simple cloud-init script which executes `ansible-pull` to bootstrap the server at first boot
- Ansible itself is executed as root (due to cloud-init), so by default all things will be done by root
  - Ansible receives it's dynamic variables from Terraform which has templated the `ansible-pull` command with CLI variables -> they will always override any other variables set within ansible
  - Ansible will bootstrap the server, in case of a failure, it will abort or never run if there is a syntax error. In such a scenario the only way to get access to the server is using the `rootkey` defined in the project
- Once the workflow has finished, the server is up & running. You can get the details of the server in the workflow summary
- To delete the machine you can simply trigger the workflow "Delete a box" and enter the name of your box

Here are some things to note when working on the machine:
- Your user is the same as your github user, ssh keys are automatically copied 
- the code-server is running for your specific user and listening on localhost:65000
- caddy is used to expose code-server to the internet on port 443/80 (bound to all interfaces) using automatic HTTPS
- ufw firewall is enabled, blocking all incoming traffic on the public IP except SSH and TCP 443 
- authentication against Github is done automatically if you are using the code-server in a browser (done using device auth)

## Preconditions

For the tevbox project to work, it's important to have some static things:
- A Hetzner project with:
  - A cost limit + notification
  - An API Token for the project that is allowed to read & write 
  - An SSH key named `rootkey` which allows emergency access to the root user (if ansible doesn't reconfiure ssh) + prevents Hetzner from sending a mail with the generated root password
- An S3 bucket / IAM policy / IAM user for the Terraform state
- This repo holding the source-code

## Open Ideas

- [ ] Run GH workflow every evening checking for left-over servers and sending you a notification
- [ ] Use "Login with Github" instead of the password-based auth of code-server
