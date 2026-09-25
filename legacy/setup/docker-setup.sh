#!/bin/bash

# Docker のインストール
curl -fsSL https://get.docker.com -o get-docker.sh
chmod +x get-docker.sh
./get-docker.sh

# ユーザーを docker グループに追加
sudo usermod -aG docker $USER
newgrp docker

# Docker Compose のインストール
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Docker Compose のバージョン確認
docker compose version 
