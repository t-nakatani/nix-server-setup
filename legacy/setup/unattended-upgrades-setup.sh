#!/bin/bash

# unattended-upgrades のインストールと設定
# セキュリティアップデートを自動的に適用する

set -euo pipefail

echo "Installing unattended-upgrades..."
sudo apt-get update
sudo apt-get install -y unattended-upgrades

echo "Configuring automatic security updates..."
sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
EOF

echo "Verifying unattended-upgrades service..."
sudo systemctl enable unattended-upgrades
sudo systemctl is-enabled unattended-upgrades

echo "unattended-upgrades setup complete."
