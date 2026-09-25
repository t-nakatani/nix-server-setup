#!/bin/bash
set -euo pipefail

# UFW (Uncomplicated Firewall) のセットアップ

# ufw がインストールされていなければインストール
if ! command -v ufw &> /dev/null; then
    echo "Installing ufw..."
    sudo apt-get update
    sudo apt-get install -y ufw
fi

# 現在の SSH ポートを sshd_config から検出 (デフォルト: 22)
SSH_PORT=$(grep -E '^Port ' /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}')
SSH_PORT="${SSH_PORT:-22}"
echo "Detected SSH port: ${SSH_PORT}"

# デフォルトポリシー: 受信を拒否、送信を許可
sudo ufw default deny incoming
sudo ufw default allow outgoing

# SSH ポートを許可
sudo ufw allow "${SSH_PORT}/tcp" comment "SSH"

# ufw を有効化 (--force で対話プロンプトをスキップ)
sudo ufw --force enable

# ステータスを表示
sudo ufw status verbose
