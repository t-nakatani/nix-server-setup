#!/bin/bash

echo "Starting base setup (packages, timezone)..."
chmod +x ./base-setup.sh
./base-setup.sh

echo "Starting Docker setup..."
chmod +x ./docker-setup.sh
./docker-setup.sh

echo "Starting Zsh setup..."
chmod +x ./zsh-setup.sh
./zsh-setup.sh

echo "Starting UFW firewall setup..."
chmod +x ./ufw-setup.sh
./ufw-setup.sh

echo "Starting fail2ban setup..."
chmod +x ./fail2ban-setup.sh
./fail2ban-setup.sh

echo "Starting unattended-upgrades setup..."
chmod +x ./unattended-upgrades-setup.sh
./unattended-upgrades-setup.sh

echo "Starting uv setup..."
chmod +x ./uv-setup.sh
./uv-setup.sh

echo "All setups are complete."
