#!/bin/bash

# Zsh のインストール
sudo apt-get install -y zsh
chsh -s $(which zsh)

# Zsh 用 Git 統合スクリプトのダウンロード
mkdir -p ~/.zsh && cd ~/.zsh
curl -o git-prompt.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
curl -o git-completion.bash https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash
curl -o _git https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.zsh

# Peco のインストール
cd /tmp
wget https://github.com/peco/peco/releases/download/v0.5.11/peco_linux_amd64.tar.gz
tar -xzf peco_linux_amd64.tar.gz
sudo mv peco_linux_amd64/peco /usr/local/bin/
peco --version
