#!/bin/bash
set -euo pipefail

echo "Updating package lists..."
sudo apt-get update -qq

echo "Upgrading installed packages..."
sudo apt-get upgrade -y -qq

echo "Installing base packages..."
sudo apt-get install -y -qq git vim curl wget unzip

echo "Setting timezone to Asia/Tokyo..."
sudo timedatectl set-timezone Asia/Tokyo
echo "Timezone: $(timedatectl show --property=Timezone --value)"

echo "Base setup complete."
