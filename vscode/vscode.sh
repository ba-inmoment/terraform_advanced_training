#!/usr/bin/env bash
set -e

echo "--> Installing VSCode"
sudo curl -fsSL https://code-server.dev/install.sh | sh
sudo systemctl enable --now code-server@$USER

echo "--> Configuring VSCode for 443 Access"
# Replaces "cert: false" with "cert: true" in the code-server config.
sed -i.bak 's/cert: false/cert: true/' ~/.config/code-server/config.yaml
# Replaces "bind-addr: 127.0.0.1:8080" with "bind-addr: 0.0.0.0:443" in the code-server config.
sed -i.bak 's/bind-addr: 127.0.0.1:8080/bind-addr: 0.0.0.0:443/' ~/.config/code-server/config.yaml
# Replace password to connect with a consistent password
sed -i.bak 's/password:.*/password: P@ssw0rd01/' ~/.config/code-server/config.yaml
# Allows code-server to listen on port 443.
sudo setcap cap_net_bind_service=+ep /usr/lib/code-server/lib/node

# sudo chmod 0755 /etc/systemd/system/shellinabox.service

echo "--> Enable and Start VSCode"
sudo systemctl restart code-server@$USER