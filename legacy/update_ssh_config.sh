#!/bin/bash
set -euo pipefail

SSH_PORT=53122
CONFIG_FILE="/etc/ssh/sshd_config"

# backup
cp $CONFIG_FILE "${CONFIG_FILE}.bak"

# port
sed -i 's/^#\?Port 22$/Port '"$SSH_PORT"'/' $CONFIG_FILE

# password
sed -i 's/^#\?PasswordAuthentication yes/PasswordAuthentication no/' $CONFIG_FILE
sed -i 's/^#PermitEmptyPasswords no/PermitEmptyPasswords no/' $CONFIG_FILE

# root login
sed -i 's/^#\?PermitRootLogin yes/PermitRootLogin no/' $CONFIG_FILE

# Ubuntu 24.04+ uses systemd socket activation for sshd.
# sshd_config alone does not control the listen port; the socket unit does.
if systemctl list-unit-files ssh.socket &>/dev/null; then
  echo "Detected systemd socket activation (Ubuntu 24.04+). Overriding ssh.socket..."
  mkdir -p /etc/systemd/system/ssh.socket.d
  cat > /etc/systemd/system/ssh.socket.d/override.conf <<EOF
[Socket]
ListenStream=
ListenStream=0.0.0.0:${SSH_PORT}
ListenStream=[::]:${SSH_PORT}
EOF
  systemctl daemon-reload
fi

# check sshd_config syntax
sshd -t

# restart: try socket-based first, then legacy sshd
if systemctl is-active --quiet ssh.socket 2>/dev/null; then
  systemctl restart ssh.socket
  systemctl restart ssh.service
else
  systemctl restart sshd
fi

echo "SSH hardening complete. Port: $SSH_PORT"
