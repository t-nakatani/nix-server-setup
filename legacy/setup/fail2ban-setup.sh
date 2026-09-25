#!/bin/bash

# fail2ban のインストール
sudo apt-get update
sudo apt-get install -y fail2ban

# jail.local の作成
sudo tee /etc/fail2ban/jail.local > /dev/null <<'EOF'
[sshd]
enabled = true
port = 53122
maxretry = 5
bantime = 3600
findtime = 600
# Ubuntu 24.04 uses ssh.service instead of sshd.service
journalmatch = _SYSTEMD_UNIT=ssh.service + _COMM=sshd
EOF

# fail2ban の有効化・起動
sudo systemctl enable fail2ban
sudo systemctl restart fail2ban

# ステータス確認
sudo fail2ban-client status
sudo fail2ban-client status sshd
