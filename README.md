# nix-server-setup

個人サーバーを NixOS と Home Manager で宣言的に管理するリポジトリです。
元の Ubuntu スクリプトは [t-nakatani/server_setup](https://github.com/t-nakatani/server_setup)
の `0306f4dc860e1dcbfe2555383bb90ad021eeda05` から引き継ぎ、`legacy/` にそのまま保存しています。
このリポジトリは別リポジトリとして運用します。

**初期状態は本番サーバーへ適用できる完成済みホストではありません。**
SSH 公開鍵・実機のディスク構成が未設定なので、`hosts/server/settings.nix` の `enable = false` により
`nixosConfigurations.server` をまだ公開しません。共通 OS とユーザー環境はテスト用構成でビルドできます。
実機情報を入力して有効化すると、同じ共通設定を使用する本番ホストが出力されます。

## 何を再現するか

- NixOS: OS のパッケージ、ユーザー、サービス、ネットワーク設定を管理。
- Home Manager: ユーザーの Zsh・Git 設定を管理。NixOS に統合し、一度の rebuild で適用。
- `flake.nix`: 構成の入口。NixOS 26.05 安定版と対応する Home Manager を使用。
- `flake.lock`: 依存関係の正確なコミットとハッシュ。必ず Git に保存。
- `nixos-rebuild`: 設定を評価し、必要なものを構築して有効化。

同じ Git コミット・lock・ホスト定義から、同じシステム構成を構築します。
DB、Docker volume、ホームの作業ファイル、SSH ホスト秘密鍵、API キーは別管理です。
Docker を有効化するだけでは、手動作成したコンテナまでは宣言的になりません。
アプリを追加するときは Compose 定義（イメージ digest を固定）と起動サービス、または
`virtualisation.oci-containers` を Git 管理し、データのバックアップを設計してください。

## 構成

```text
flake.nix / flake.lock             依存関係とホスト一覧
hosts/server/settings.nix         個人・ホスト固有値
hosts/server/configuration.nix    起動方式・ネットワーク
hosts/server/hardware-configuration.nix  実機で生成して置換
modules/common.nix               OS・SSH・Docker・セキュリティ・更新
home/user.nix                    Zsh・peco・Git
tests/                           共通構成のビルド用値と VM 統合テスト
.github/workflows/               検証と lock 更新 PR
legacy/                          以前の Ubuntu 用ファイル（NixOS では実行しない）
```

| Ubuntu での処理 | NixOS での対応 |
| --- | --- |
| apt の基本パッケージ | `environment.systemPackages`: git, vim, curl, wget, unzip |
| timedatectl | `time.timeZone = "Asia/Tokyo"` |
| Docker の curl installer | `virtualisation.docker.enable` |
| Compose v1 バイナリ | Nixpkgs の Compose、`docker compose` に統一 |
| adduser / usermod / chsh | `users.users`、Zsh、wheel/docker グループ |
| sudoers ファイルの書き込み | 対象ユーザーだけの `NOPASSWD: ALL` |
| sshd_config の sed と socket override | `services.openssh`、53122/tcp、鍵のみ、root 禁止 |
| UFW | `networking.firewall` と Docker 向け転送制限 |
| jail.local | `services.fail2ban`: 5 回、3600 秒、600 秒 |
| unattended-upgrades | Git 上の lock 更新 PR と承認済み構成の定期適用 |
| uv installer | `pkgs.uv` |
| peco tarball / Git master のスクリプト | `pkgs.peco`、Zsh 標準の Git 補完と `vcs_info` |
| .zshrc | Home Manager: 履歴 150000 件・履歴共有・Ctrl-R 検索・Git 状態・日時 |

元の `.zshrc` の重複したプロンプトは、最後に有効だった「パス・Git・日時」に統合しました。
履歴は辞書順ではなく新しい順に検索し、キャンセル時は入力中のコマンドを保持します。
Ubuntu 固有の `ssh.service` ログ指定は引き継がず、NixOS の fail2ban 標準の journal backend を使います。

## 初回インストール

### 1. 新しい NixOS サーバーを用意する

Ubuntu に Nix を入れるだけでは NixOS にはなりません。新しい VM / サーバーで構築・検証し、
既存 Ubuntu のデータ移行・切り替えは別途行います。
[公式インストール手順](https://nixos.org/manual/nixos/stable/#sec-installation)に従い、
実際の BIOS/UEFI とストレージに合わせてパーティションを準備します。
このリポジトリはディスクの初期化を自動化しません。

以下は NixOS インストールメディアから対象ディスクを `/mnt`、EFI パーティションを `/mnt/boot` に
マウントした後の例です。管理画面のコンソール / rescue 経路を確保してから実施してください。

```sh
sudo nixos-generate-config --root /mnt
nix --extra-experimental-features 'nix-command flakes' shell nixpkgs#git
git clone https://github.com/t-nakatani/nix-server-setup.git /tmp/nix-server-setup
cd /tmp/nix-server-setup
sudo cp /mnt/etc/nixos/hardware-configuration.nix hosts/server/hardware-configuration.nix
```

生成された `/mnt/etc/nixos/configuration.nix` も読み、必要な起動設定を
`hosts/server/configuration.nix` に反映してください。現在の例は UEFI + `/boot` です。
BIOS の場合は systemd-boot を無効にし、実機に合う GRUB 設定などに置き換えます。
静的 IP、VPS 固有のネットワーク、追加ディスクもホスト側で設定します。

### 2. 自分の値を設定する

`hosts/server/settings.nix` を編集します。

- `username`: ログインする一般ユーザー。
- `hostName`: OS のホスト名。flake の選択名 `server` とは別の値です。
- `system`: サーバーが Intel/AMD なら `x86_64-linux`、ARM64 なら `aarch64-linux`。
- `sshPublicKeys`: 手元の `.pub` ファイルの全文。秘密鍵は入れません。
- `gitName` / `gitEmail`: 必要なら設定。公開レポなので公開してよい値にしてください。
- `enable = true`: 実機情報と公開鍵が設定できたら有効化。
- `upgradeFlake`: 初回は `null` のままで構いません。

SSH 公開鍵が空なら評価に失敗し、未置換の hardware ファイルも必ず失敗します。
簡易書式チェックは鍵の実用性を保証しません。手元の鍵を `ssh-keygen -lf <公開鍵ファイル>` で確認し、
対応する秘密鍵を保持していることを確認してください。

`stateVersion` / `homeStateVersion` は互換性の基準です。パッケージ更新のたびに上げません。
既存 NixOS を取り込む場合はその環境の値を引き継ぎます。

### 3. 検証してインストール

```sh
# flakes は Git の未追跡ファイルを自動で含めないため、追加ファイルを stage する。
git add hosts
nix --extra-experimental-features 'nix-command flakes' flake check --no-build
nix --extra-experimental-features 'nix-command flakes' build \
  .#nixosConfigurations.server.config.system.build.toplevel --no-link
sudo nixos-install --flake .#server --no-root-passwd
```

root のパスワードログインには依存しません。インストール後の一般ユーザーもパスワードはロックされ、
SSH 鍵とパスワードなし sudo を使用します。復旧はプロバイダーのコンソール / rescue / インストールメディアから行います。
初回の SSH ログインは再起動するまで試せないので、コンソールが必須です。

設定を今後編集できるよう、インストーラー上で次を実行して Git の作業ツリーも残します。
以下のバックアップ名が既に存在する場合は別名にしてください。

```sh
sudo mv /mnt/etc/nixos /mnt/etc/nixos.generated-backup
sudo cp -a /tmp/nix-server-setup /mnt/etc/nixos
sudo chown -R root:root /mnt/etc/nixos
```

編集したホスト設定は開発端末にも取り込み、レビュー・commit・push してください。
その完了前にサーバーで pull すると未コミット変更と衝突するので、先に Git と実機の設定を揃えます。
公開レポを読むだけならサーバーに GitHub 秘密鍵は不要です。`/etc/nixos` は root 所有で管理します。

クラウド側のファイアウォール / Security Group にも 53122/tcp を許可し、再起動後に別端末から確認します。

```sh
ssh -p 53122 <username>@<IP>
sudo -n true
docker info
docker compose version
uv --version
```

## 日常の rebuild と SSH の変更

`nixos-rebuild` はコミット前の作業ツリーも使用できます。安定運用ではコミットして適用対象を記録します。

```sh
cd /etc/nixos
sudo git pull --ff-only
sudo nixos-rebuild build --flake .#server
sudo nixos-rebuild test --flake .#server
# 別端末から鍵でログインし、sudo・Docker・各サービスを確認した後:
sudo nixos-rebuild switch --flake .#server
```

`build` は構築のみ。`test` は現在の稼働設定を変更しますが、次回起動の既定にはしません。
**`test` は接続が切れたら自動復旧する仕組みではありません。**
既存 SSH 接続を残すだけでは復旧保証にならないため、コンソールを確保してください。
SSH/ネットワーク変更を無人で適用する前に、VM とコンソールありの実機で確認します。

## update と自動適用

更新は「新しい依存版を Git に記録する」と「その版をサーバーに適用する」の2段階です。
lock を固定して rebuild するだけでは、新しいセキュリティ修正は入りません。

```sh
# 開発端末または Linux の検証環境
nix flake update
nix flake check --no-build --all-systems
nix build .#checks.x86_64-linux.system --no-link
# 有効化済みの各ホストも、その CPU の Linux で build する。
nix build .#nixosConfigurations.server.config.system.build.toplevel --no-link
# 差分確認 → commit → PR → 検証 → merge
```

`.github/workflows/update-lock.yml` は毎週、日本時間の月曜 06:00 頃に更新を提案します。
選択済みの安定版系列を維持し、共通 x86_64 構成と統合 VM を検証してから PR を作成します。
GitHub の Settings → Actions → General で Actions に PR 作成を許可してください。
標準 `GITHUB_TOKEN` で作成した PR は別の CI を自動起動しないため、PR ブランチを選んで
**Check NixOS を workflow_dispatch で実行**し、ARM と本番ホストの結果も確認してからマージします。
自動マージは設定していません。PR を放置するとセキュリティ修正も入りません。

初回導入・push・復旧手順の確認後、`settings.nix` の例に従って `upgradeFlake` に
このリポジトリの main とホスト名を指定すると `system.autoUpgrade` が有効になります。
毎日 04:40〜05:10 JST に main の構成を取得し、Git 上の lock を変更せずに適用します。
ローカル `/etc/nixos` を pull する方式ではないため、その作業ツリーは自動更新されません。
`upgradeFlake = null` の間は自動適用されません。手動更新を続けてください。

自動適用は lock だけでなく main にマージされた **構成変更も含みます**。
SSH/ネットワーク変更時はタイマーを止めて手動検証し、再開します。

```sh
sudo systemctl stop nixos-upgrade.timer
# 検証・手動適用の後（自動更新を有効化済みの場合のみ）
sudo systemctl start nixos-upgrade.timer
systemctl list-timers nixos-upgrade.timer
journalctl -u nixos-upgrade.service
```

自動再起動はしません。カーネル等の更新はメンテナンス時間に手動で再起動して確認してください。
安定版にも互換性問題はあり得ます。リリース系列の変更は flake.nix の両 input を明示的に変更し、
リリースノート・サポート期限を確認して検証します。

## rollback

```sh
sudo nixos-rebuild switch --rollback
```

起動できない場合はブートメニューから以前の generation を選びます。
接続できない場合はコンソール / rescue から復旧します。
自動適用を有効化していた場合は先にタイマーを止め、Git 上の原因コミットも revert してください。
そうしないと、次の更新で問題の構成が再適用されます。

rollback は OS の構成・パッケージを戻す機能です。DB や Docker volume の内容、
実行済みのデータ移行、ホームの履歴、外部システムの状態は戻りません。
Home Manager の実行結果も確認し、必要に応じて戻した Git コミットから rebuild します。

古い generation を削除・GC すると、その世代に戻れなくなります。
自動 GC は初期設定では無効です。ディスクと `/boot` の空き容量を監視し、
動作確認済みの世代を残す保存期間を決めてから削除します。

## 新しいサーバーの追加

1. `hosts/server` を `hosts/<new-host>` にコピー。
2. `settings.nix` のユーザー・ホスト名・CPU・公開鍵・更新 URL を設定。
3. hardware ファイルは **新しい実機で生成**して置換。起動・ネットワークも確認。
4. `flake.nix` の `hosts` に `<new-host> = ./hosts/<new-host>;` を追加。
5. `enable = true` にし、`git add hosts flake.nix`、評価・ビルド・commit。
6. `sudo nixos-rebuild switch --flake .#<new-host>` で適用。

flake の選択名は `hosts` のキーです。`settings.hostName` を変えるだけでは選択名は変わりません。
SSH ポートは共通の 53122 です。

## Docker と firewall

ホストへの新規 TCP 接続は 53122 だけを許可します。UDP サービスポートは開けません。
ループバック、確立済み通信への応答、DHCP/IPv6 の動作に必要な通信など、
NixOS 標準のネットワーク制御通信まで一律に遮断するという意味ではありません。

Docker は通常のホスト firewall を迂回する転送ルールを作成するため、追加の nftables ルールで
外部からの新規転送を拒否しています。標準の `docker0` と `br-*` からの通信・戻り通信は許可します。
カスタム名の bridge、macvlan、Swarm、VPN、ルーター用途はこの構成の対象外です。
Docker bridge の IPv4/IPv6 公開が外部から遮断されることを VM テストに含めています。

既定のポートバインドも loopback にしていますが、Compose でも明示してください。

```yaml
services:
  app:
    # image は実際のイメージと digest を指定する
    ports:
      - "127.0.0.1:8080:8080"
```

```sh
ssh -p 53122 -L 8080:127.0.0.1:8080 <username>@<IP>
# 手元で http://localhost:8080 を開く
```

Docker グループと NOPASSWD sudo は実質的な root 権限です。
信頼する管理ユーザー向けの設定であり、非信頼ユーザーの隔離には使いません。
クラウド側でも IPv4/IPv6 両方の ingress を制限し、実機の外部到達性を確認してください。

## secrets

公開鍵は Git に置けます。秘密鍵・トークン・パスワードは Git や Nix の式に埋め込みません。
Nix store は一般ユーザーから読めるため、秘密ファイルを Nix の path 値で参照するだけでも危険です。
今回、秘密情報を配布する必要はないので secrets module は追加していません。

将来は **sops-nix + age** を第一候補とし、暗号化したファイルを Git に置き、復号鍵はホストへ別経路で配布します。
少数の秘密ファイルだけなら agenix も候補です。サービスは起動時に `/run/secrets/...` 等から読み込みます。
復号鍵のバックアップ・ローテーション・新規ホストの復旧手順まで含めて設計してください。
非公開 GitHub レポを自動取得する場合の deploy key も、read-only のものを root に別途配置します。

## 検証

```sh
nix flake check --no-build --all-systems  # 両 CPU の評価
nix build .#checks.x86_64-linux.system --no-link -L
nix build .#checks.aarch64-linux.system --no-link -L
# 対応する CPU の Linux + KVM を推奨。NixOS を2台起動する。
nix build .#checks.x86_64-linux.integration --no-link -L
```

`nix flake check`（--no-build なし）は実行環境の system に対応するチェックをビルドし、統合 VM も実行します。
macOS では Linux の実機・VM・remote builder が必要です。
CI は両 CPU の評価・ビルド、および x86_64 の VM テストを行います。
テストは鍵ログイン・root 拒否・旧ポート拒否・sudo・Compose・uv・Zsh・Docker ポート遮断・
実際の SSH 失敗を使った fail2ban の ban を確認します。テスト用の秘密鍵は VM 内で一時生成します。

合格しても、実機のディスク、起動方式、クラウド firewall、ネットワーク、利用者の鍵は別途確認が必要です。
初回作成時の検証結果と未確認範囲は [VALIDATION.md](VALIDATION.md) を参照してください。

既存ホームへ Home Manager を導入すると、既存の `.zshrc` 等と衝突して有効化が失敗する場合があります。
その場合は内容をバックアップ・比較してからファイルを退避し、再適用してください。
Ubuntu の通常バイナリや uv がダウンロードする Python は NixOS でそのまま動くとは限りません。
Python の実行環境も固定したいアプリは別の devShell / Nix パッケージで Python と依存関係を宣言します。

## 参考

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Home Manager: NixOS integration](https://nix-community.github.io/home-manager/installation/nixos.html)
- [Automatic system upgrades](https://wiki.nixos.org/wiki/Automatic_system_upgrades)
- [Docker packet filtering](https://docs.docker.com/engine/network/packet-filtering-firewalls/)

`legacy/` は移行確認が終わるまで保持し、確認後に別コミットで削除できます。
