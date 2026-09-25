# サーバーセットアップ

## 手順概要

1. ユーザー作成・SSH 鍵登録 (手動)
2. SSH ハードニング (手動)
3. メインセットアップ (自動: `main-setup.sh`)
4. 個別設定 (手動: git config, GitHub SSH 鍵, sudo NOPASSWD)

---

## 1. ユーザー作成

```
sudo adduser {newuser}
sudo usermod -aG sudo {username}
```

### 公開鍵でのログインを可能に

ローカルマシンから実行:
```
ssh-copy-id {username}@{hostname or ip}
```

## 2. SSH ハードニング

ポート番号変更・パスワード認証無効化・root ログイン無効化を行う。

サーバー上でこのリポジトリを clone:
```
cd ~/.ssh
ssh-keygen -t rsa
cat id_rsa.pub
# → GitHub に登録
git clone git@github.com:t-nakatani/server_setup.git
```

SSH 設定を上書き:
```
chmod +x update_ssh_config.sh
sudo ./update_ssh_config.sh
```

ローカルの `~/.ssh/config` に追加:
```
Host {host-name}
    HostName {hostname or ip}
    User {username}
    Port 53122
    IdentityFile ~/.ssh/id_rsa
```

## 3. メインセットアップ

以下を一括で実行する:

| ステップ | 内容 |
|----------|------|
| base-setup | apt update/upgrade, 基本パッケージ (git, vim, curl, wget, unzip), タイムゾーン (Asia/Tokyo) |
| docker-setup | Docker, Docker Compose |
| zsh-setup | Zsh, peco, git-prompt |
| ufw-setup | UFW ファイアウォール (SSH ポートのみ許可) |
| fail2ban-setup | fail2ban (SSH ブルートフォース対策: maxretry=5, bantime=1h) |
| unattended-upgrades-setup | セキュリティアップデート自動適用 |
| uv-setup | uv (Python パッケージマネージャ) |

```
cd setup
chmod +x main-setup.sh
sudo ./main-setup.sh
```

### 個別実行

各スクリプトは単独でも実行可能:
```
cd setup
sudo ./base-setup.sh
sudo ./docker-setup.sh
# ...
```

### ステータス確認

```
# UFW
sudo ufw status verbose

# fail2ban
sudo fail2ban-client status sshd

# unattended-upgrades
systemctl is-enabled unattended-upgrades
cat /etc/apt/apt.conf.d/20auto-upgrades

# Docker
docker --version && docker compose version

# uv
uv --version
```

## 4. 個別設定 (手動)

### git config

```
git config --global user.name "My Name"
git config --global user.email "myname@example.com"
```

### GitHub SSH 鍵

```
ssh-keygen -t ed25519 -C "{host-name}"
cat ~/.ssh/id_ed25519.pub
# → GitHub Settings → SSH and GPG keys に登録

ssh-keyscan github.com >> ~/.ssh/known_hosts
ssh -T git@github.com
```

### sudo NOPASSWD (任意)

指定ユーザーに対してパスワードなしで sudo を許可する。

```
sudo ./setup/sudo-nopasswd-setup.sh {username}
```

引数省略時は `$SUDO_USER` (sudo の呼び出し元ユーザー) が対象。
