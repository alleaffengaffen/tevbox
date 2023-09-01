# tevbox
Technat's Development Box in the cloud

## Goal

From time to time we need a development environment on the go. While there are many solutions out there, I prefer to setup my own. This has multiple reasons:
- performance of cloud-based IDEs is often rather poor or insufficient (in my personal experience)
- control of the network stack is often not given (e.g no public IP or direct access to the machines NIC)
- they usually stop working when you log of

To fix these issues, this repo does the following:
- bootstrap a new cloud instance on any openstack provider
- joins the server to my [tailnet](https://tailscale.com), for remote-access and internet-exposing
- installs and runs the [vs-code server](https://github.com/microsoft/vscode-remote-release) on the instance
- runs any scripts / configurations you want
- stops the server at a fixed time in the evening while notifing you about this so that you could intervent if required


