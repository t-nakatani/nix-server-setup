#!/bin/bash
set -euo pipefail

# sudo 経由の場合は呼び出し元ユーザーにインストール
TARGET_USER="${SUDO_USER:-$(whoami)}"
TARGET_HOME=$(eval echo "~${TARGET_USER}")

echo "Installing uv for ${TARGET_USER}..."
sudo -u "${TARGET_USER}" bash -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'

# .zshrc に PATH を追加（未追加の場合のみ）
ZSHRC="${TARGET_HOME}/.zshrc"
if [ -f "$ZSHRC" ] && ! grep -q 'local/bin/env' "$ZSHRC"; then
    echo 'source $HOME/.local/bin/env' >> "$ZSHRC"
    chown "${TARGET_USER}:${TARGET_USER}" "$ZSHRC"
    echo "Added uv to .zshrc PATH"
fi

echo "uv setup complete."
