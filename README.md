# tevbox

Technat's Development Box in the cloud

## Goal

From time to time we need a development environment on the go. While there are many solutions out there, I prefer to setup my own. This has multiple reasons:
- performance of cloud-based IDEs is often rather poor or insufficient (in my personal experience)
- control of the network stack is often not given (e.g no public IP or direct access to the machines NIC)
- they usually stop working when you are inactive for some time

So this repo provides a solution how you can quickly create a fresh cloud server ready for you to code and tinker on.

## How it works

There's a Terraform file called [openstack.tf](./openstack.tf) in this repo, that spins up a new instance on Openstack whenever Terraform is triggered (Terraform Cloud). The instance will have the latest LTS-release of Ubuntu & a public-IP. In order to further configure the instance, cloud-init is used.

Cloud-init will do the following:
- create a user named `technat`
- install and configure tailscale (so that in the end the device is connected to your tailnet)
- disable the internal OpenSSH server
- setup the development environment by using the [cloud-script.sh](./cloud-script.sh)

Once cloud-init has finished, the device is available in your tailnet as `tevbox`. You can ssh into it form any tailscale-enabled device without any further authentication. All that was configured via the script should be available to you to start coding.

Once you shutdown the instance or run Terraform destroy, the device is automatically removed from your tailnet, thanks to a systemd service that's run on shutdown.

** Since the instance is a one-shot instance, remember to safe your work always! **

### Permannent secrets

For this solution to work we need some permanent things:
- A Terrraform workspace
- an Openstack project with an application credential saved in the Terraform workspace
- A tailscale API key to generate tailnet keys
- This repo holding the source-code

## Open Ideas

Some things to improve:
- [ ] Finish configuring the instance (currently it's a blank instance, some tools would be cool)
- [ ] Imform the user about the running instance using a cronjob that executes a curl against Telegram's API