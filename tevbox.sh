#!/bin/sh
# Note: must be executed as root

### APT
# https://caddyserver.com/docs/install#debian-ubuntu-raspbian
apt install -y apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
apt update
apt install caddy
apt dist-upgrade -y

### SSH
%{ if enable_ssh }
systemctl disable --now ssh
systemctl mask ssh
%{ endif }

### User
useradd ${username} -m -s /usr/bin/bash -G sudo -p ${password}
echo "${username} ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers
loginctl enable-linger ${username} # used to autostart the systemd/user session that reads env vars for code-server

### Caddy
caddy add-package github.com/caddy-dns/hetzner 
cat <<EOF | tee /etc/caddy/Caddyfile
${fqdn} {
  reverse_proxy 127.0.0.1:65000
  tls {
    dns hetzner ${hetzner_dns_token}
  }
}
*.${fqdn} {
  reverse_proxy 127.0.0.1:65000
  tls {
    dns hetzner ${hetzner_dns_token}
  }
}
EOF
sudo systemctl restart caddy

### Code-server
curl -fsSL -o /tmp/install.sh https://code-server.dev/install.sh 
chmod +x /tmp/install.sh
HOME=/root /tmp/install.sh
sudo systemctl enable --now code-server@${username}
sleep 10 # give the server some time to create the directories
cat <<EOF | sudo -u ${username} tee /home/${username}/.config/code-server/config.yaml
bind-addr: 127.0.0.1:65000
auth: password
password: ${password}
cert: false
proxy-domain: ${fqdn}
EOF

### Code OSS
sudo -u ${username} code-server --install-extension  redhat.vscode-yaml
sudo -u ${username} code-server --install-extension  vscodevim.vim
sudo -u ${username} code-server --install-extension  golang.Go
sudo -u ${username} code-server --install-extension  hashicorp.terraform
sudo -u ${username} code-server --install-extension  ms-kubernetes-tools.vscode-kubernetes-tools
cat << EOF |sudo -u ${username} tee /home/${username}/.local/share/code-server/User/settings.json
{
  "workbench.colorTheme": "Solarized Dark",
  "redhat.telemetry.enabled": false,
  "workbench.sideBar.location": "right",
  "workbench.startupEditor": "none",
  "terminal.integrated.defaultProfile.linux": "zsh",
  "explorer.confirmDragAndDrop": false
}
EOF
sudo systemctl restart code-server@${username}
         
### Chezmoi
curl -fsSL -o /tmp/chezmoi-install.sh https://get.chezmoi.io
chmod +x /tmp/chezmoi-install.sh
sudo -u ${username} /tmp/chezmoi-install.sh -b /home/${username}/.local/bin
sudo -u ${username} /home/${username}/.local/bin/chezmoi init --apply ${username}
