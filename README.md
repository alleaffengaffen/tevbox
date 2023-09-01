# tevbox
Technat's Development Box in the cloud

## Goal

From time to time we need a development environment on the go. While there are many solutions out there, I prefer to setup my own. This has multiple reasons:
- performance of cloud-based IDEs is often rather poor or insufficient (in my personal experience)
- control of the network stack is often not given (e.g no public IP or direct access to the machines NIC)
- they usually stop working when you log of

To fix these issues, this repo does the following:
- create a new cloud instance using Terraform's openstack provider
- execute ansible-pull on the new instance to configure it as a development machine
