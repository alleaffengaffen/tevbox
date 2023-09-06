# tevbox

Technat's Development Box in the cloud

## Goal

From time to time we need a development environment on the go. While there are many solutions out there, I prefer to setup my own. This has multiple reasons:
- performance of cloud-based IDEs is often rather poor or insufficient (in my personal experience)
- control of the network stack is often not given (e.g no public IP or direct access to the machines NIC)
- they usually stop working when you are inactive for some time

So this repo provides a solution how you can quickly create a fresh cloud server ready for you to code and tinker on.

## How it works

We use a fire & forget apoproach with Github actions and Terraform. There's a Terraform file called [openstack.tf](./openstack.tf) in this repo, that spins up a new instance on Openstack whenever Terraform is triggered. The instance will have the latest LTS-release of Ubuntu & a public-IP. In order to further configure the instance, cloud-init is used.

Cloud-init will do the following:
- create a user named `technat`
- install some commong debugging packages
- install and configure tailscale (so that in the end the device is connected to your tailnet)
- enable and configure UFW (since the instance is public)
- configure the openssh-server
- setup the development environment by using the [cloud-script.sh](./cloud-script.sh)

Once cloud-init has finished, the device is available in your tailnet as `tevbox-XXX`. You can ssh into it form any tailscale-enabled device without any further authentication or on it's public IP with your SSH-key. All that was configured via the script should be available to you to start coding. You will now that the instance is ready when the Github Action has finished.

### Permannent secrets

For this solution to work we need some permanent things:
- an Openstack project with:
  - an application credential saved as repository secrets
  - a security group named `unrestricted` in the openstack project that does exactly what it's name says
- A tailscale API key to generate tailnet keys saved as repository secret
- This repo holding the source-code

## Open Ideas

- [ ] Install and setup [code-server](https://coder.com/docs/code-server/latest) automatically
- [ ] Provide an easy way to destroy the instance once it's no longer needed (maybe a script that curls openstack API's if the user want's it)
