#!/bin/sh
# must be executed as root

### install caddy
# https://caddyserver.com/docs/install#debian-ubuntu-raspbian
apt install -y apt-transport-https curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
apt update
apt install caddy
apt dist-upgrade -y

### disable regular ssh
systemctl disable --now ssh
systemctl mask ssh

### create user
useradd ${username} -m -s /usr/bin/bash -G sudo -p ${password}
echo "${username} ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers
loginctl enable-linger ${username} # used to autostart the systemd/user session that reads env vars for code-server

### configure caddy
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

### install code-server
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
sudo systemctl restart code-server@${username}

### install tailscale
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --ssh --auth-key "${tailscale_auth_key}"

### install chezmoi
curl -fsSL -o /tmp/chezmoi-install.sh https://get.chezmoi.io
chmod +x /tmp/chezmoi-install.sh
sudo -u ${username} /tmp/chezmoi-install.sh -b /home/${username}/.local/bin
sudo -u ${username} /home/${username}/.local/bin/chezmoi init --apply ${username}
