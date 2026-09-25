# 検証記録

2026-09-25〜26（JST）に、ローカルの ARM64 Linux コンテナと GitHub Actions で検証しました。
実機への適用と、共通構成の検証は区別しています。

[成功した GitHub Actions 実行](https://github.com/t-nakatani/nix-server-setup/actions/runs/36151927424)
（検証対象コミット `5111c51c637b6a2c9e49c5b23d637411da7fd4a0`）。
この記録を追加する最終コミットは文書のみの変更です。

| 検証 | 結果 |
| --- | --- |
| `nix flake check --no-build --all-systems` | 成功。x86_64 / ARM64 とも評価済み |
| x86_64 共通 OS + Home Manager | GitHub Actions の Linux ビルド成功 |
| ARM64 共通 OS + Home Manager | ローカル Linux と GitHub Actions の両方でビルド成功 |
| ARM64 VM 統合テスト | VM 実行は未実施。ARM64 は評価・OS ビルドまで |
| x86_64 VM 統合テスト | 成功。2台の VM で SSH・Docker・firewall・fail2ban を実行検証 |
| SSH 公開鍵が空の場合 | assertion により拒否されることを確認 |
| hardware ファイル未置換の場合 | assertion により拒否されることを確認 |
| 自動更新を有効化した場合の評価 | `upgrade = false`、lock 変更禁止、再起動無効を確認 |
| legacy の13ファイル | 元の内容を変更せず保持 |

VM テストはサービス起動だけでなく、外部クライアントからの鍵ログイン、認証設定、
一般ユーザーの sudo / Docker / Compose / uv / Zsh、コンテナポートの到達性、
ファイアウォール再読み込み、fail2ban の実際の ban を検証します。

ローカル検証に使用した Nix は 2.35.2。依存の正確なコミット・ハッシュは `flake.lock` を参照してください。
本番ホストの固有値と実機情報は未提供なので、`nixosConfigurations` は初期状態では空です。
CI は共通構成を専用 fixture で検証し、ホストを有効化した後はそのホストのビルドも実行します。

未実施: 実サーバーへのインストール、実ディスクからの起動、ユーザー自身の鍵での接続、
クラウド側 firewall との組み合わせ、データ移行、実機 rollback、自動更新の実機適用。
これらは初回導入時に README の手順に従って確認してください。

週次 lock 更新ワークフローは登録済みですが、Actions の PR 作成・承認権限は未許可です。
許可設定を行うまでは PR 作成ステップが失敗します。
当面は README の手動 lock 更新手順を使用できます。サーバー側の自動適用も初期値は無効です。
