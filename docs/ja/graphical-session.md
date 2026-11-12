---
title: グラフィカルセッション
description: グラフィカルログインフローを通じてARGVUSを開始します。
---
グラフィカルエントリポイントは`argvus session`です。これはセッション環境を設定し、argvus startに委譲します。`argvus start`はそれをユーザーマネージャにインポートし、パッケージ化されたまたはユーザーのHyprland Lua設定を検証し、検出されたグラフィック互換性設定を適用し、Hyprlandを起動してコンポジタの準備完了を待機します。

ログは`~/.local/state/argvus/session.log`に書き込まれます。グリーターはログイン前に独自のユーザーとして実行されるため、ログイン前の出力は`/run/argvus-greeter/session.log`に保持され、セッション開始時に`session.log`に追加されます。セッションログにHyprlandからの起動警告が表示されない場合は、まずこのファイルを確認してください。

セッションは、ログインマネージャ（例えばsource_profile=falseを使用したgreetd）が環境変数をエクスポートしない場合でも、シェル`PATH`環境変数が適切なデフォルトに設定されていることを保証します。これにより、Hyprlandの起動時に使用される `source_profile=false` `hyprland-dialog`などのユーティリティが、子プロセスによって見つけられることが保証されます。

Hyprland の準備ができると、`argvus sessionctl` が `argvus-session.target` を起動します。このターゲットはタスクバー、コントロールパネル、通知、壁紙、アイドル処理、クリップボード、SSH エージェント、Secret Service プロバイダーおよび関連するサービスを起動します。ログイン引き渡しからこれらのサービスが起動し、壁紙とタスクバーが画面に表示されるまで、シングルのロードスピナーが画面に表示され続けます（最大でさらに 1.5 秒）。Hyprland を起動する前に、`argvus-start` は設定投影（`argvus-config.service`）をキューに入れ、これはコンポジタ起動中に実行され、グリータの DRM 引き渡しサーフェスにディスプレイを解放するよう依頼します（`/usr/lib/argvus/greeter/handoff --send release`）。そのサーフェスが動作しているとき、まず `loginctl activate` でセッションをアクティブにするため、Hyprland はバックグラウンドの VT 上で起動することはありません。その後、セッションスピナーはサーフェスに Hyprland の最初のフレームを隠していたオーバーレイを削除するよう指示します。

デスクトップが準備完了すると、セッションはTTY、ARGVUS Greeterおよびその他のログインマネージャ向けに`argvus welcome --if-needed`を実行します。ユーザー別の進行状況記録`opened`、完了または閉じる操作がない場合、統合コントロールセンターのウェルカムページを開きます。最初の正常なレンダリングは`opened`を`${XDG_STATE_HOME:-$HOME/.local/state}/argvus/welcome/progress.json`に保存し、後のログイン時に再度開くのを防ぎます。`/etc/skel`には依存しません。その記録がない既存アカウントにも自動的に一度開く操作が行われます。レンダリング前の失敗は、次回のログインで再試行の機会を提供します。手動の`argvus welcome`は引き続き利用可能です。

`PATH` は、これらのディレクトリが存在する場合、`~/.local/bin` および `~/.cargo/bin` も先頭に追加されるので、そこにインストールされたツールはコンポジターやサービスから見えるようになります。`EDITOR` および `VISUAL` は、コントロールセンターのデフォルトアプリ（`TERMINAL_EDITOR`）から設定されたデフォルト端末エディタであり、システムデーモンユーザーマネージャ、D-Bus アクティベーション、および Hyprland にエクスポートされるため、セッションから起動された端末やサービスはそれらを継承します。SSH エージェント（`argvus-ssh-agent.service`、`openssh` 由来）は `$XDG_RUNTIME_DIR/ssh-agent.socket` で待機し、`SSH_AUTH_SOCK` をユーザーマネージャに公開します。ARGVUS エージェントが起動すると、ユーザーマネージャ内の `SSH_AUTH_SOCK` を置き換えます。gnome-keyring や gcr などの他のエージェントがソケットを所有する必要がある場合は、`systemctl --user mask argvus-ssh-agent.service` を使用して ARGVUS ユニットを無効にしてください。Hyprland が終了すると停止するため、これらのサーフェスはログアウト後に孤立したプロセスとして残りません。

シークレットサービスのプロバイダーは`argvus-secret-service.service`です。これはsecretsコンポーネントのみで上流の`gnome-keyring-daemon.service`を開始するため、SSHキーを提供せず、 `secrets` `SSH_AUTH_SOCK`は`argvus-ssh-agent.service`が所有したままになります。`gnome-keyring`がインストールされていない場合、このユニットはスキップされます。パッケージは`gnome-keyring`をオプション依存関係として宣言しており、CalDAVのパスワードをそこに保存する`argvus-taskbar-calendar`も同様です。ARGVUSはPAMを変更しないため、ログイン時にキーチェーンは解除されません：最初にそれを使用するアプリケーションがキーチェーンのパスワードを要求し、その時にログインコレクションが作成されます。状態は`argvus sessionctl secret-service-status`で確認でき、missing、stopped、running、locked、unlockedの状態を報告します。KWalletやKeePassXCにシークレットサービスを所有させたい場合は、ARGVUSユニットを`systemctl --user mask argvus-secret-service.service`で無効にしてください；セッションが停止するとプロバイダーも停止します。

このセッションは、Wayland およびデスクトップ環境の変数も systemd ユーザーマネージャにインポートします。実行中のセッションを確認またはリロードするには:

```sh
argvus sessionctl status
argvus sessionctl logs
argvus sessionctl reload
```

`reload` は、すでにコミットされた世代を適用します。`argvus config apply-theme`、`accent`、`set`/`patch` のようなコマンドやウィジェット・テレメトリブロックの変更が変更を単に予測した場合、リロードは再度投影するのではなく、投影マニフェストから影響を受けたコンシューマを復元します。これは保留中のプランが存在しない場合（例えばセッション開始時）にのみ投影します。ランタイムに関連するセクションが変更されていない場合、Hyprland のリロードやサービスの再起動なしで正常に終了します。変更が存在する場合、セッション統合を再適用し、影響を受けたコンポジタおよびデスクトップサーフェスのみをリロードします。スプラッシュは、サーフェスを再作成する場合にのみリロードをカバーします：Waybar バー（タスクバーまたはウィジェット・テレメトリ）の再起動、コントロールパネルの再起動、またはフォールバック `full` プランです。テーマ、アクセント、効果、フォント、ウィンドウレイアウト、壁紙の変更は、`argvus config theme-runtime consumers` および `wallpaper`、Hyprland の `/reload` のように、スプラッシュなしでその場でリロードされます。 何もすることがない状態でのリロードは何も表示しません。繰り返しのリロードは直列化され、変更のない部分はそのコンシューマを再起動しません。`apply-config`はこの操作の明示的なエイリアスです。表示されると、リロードのスプラッシュは作業中は不透明であり、中間のデスクトップは表示されません。コンポジターやログイン環境を再起動する必要がある場合のログアウトの代替手段ではありません。

プロジェクションを完了できない場合、リロードはデスクトップのサーフェスを再起動する前に停止します。`argvus sessionctl logs`を確認し、再試行する前に`argvus config validate`を実行してください。これにより、テーマのプロジェクションに失敗してWaybar、通知、またはコントロールパネルが古いテーマの混合状態で動作し続けるのを防ぎます。

デフォルトのログイン統合はgreetdです。[Greeter](/docs/components/argvus-greeter/)および[session troubleshooting](/docs/user-guide/troubleshooting/session-startup/)を参照してください。

サービスの所有権と起動シーケンスについては、[Runtime lifecycle](/docs/developer-guide/architecture/runtime-lifecycle/) を参照してください。

## ナイトライト

`argvus-session` は `hyprsunset>=0.4.0` に依存しており、セッションターゲットを通じて上流のユーザーサービスを起動しますが、2番目のデーモンは有効にしません。`argvus-night-light-init.service` はエントリ時に保存された状態を適用します。タイマーは毎分および時計/タイムゾーンの変更後に固定されたローカルスケジュールを評価します。スケジューリングがオフの場合、定期チェックは手動の状態を変更しません。上流サービスはログアウト時に `graphical-session.target` に従います。

パッケージ化されたドロップインは、`--identity` で Hyprsunset を起動し、サービスローカル `XDG_CONFIG_HOME`/`XDG_CONFIG_DIRS` が `/usr/share/argvus/session/config/night-light` を指すように設定されており、その構成にはネイティブプロファイルは含まれていません。これにより、競合するスケジューラや、上流のデフォルト 6000 K での起動を回避します。また、インストール中でも ARGVUS 外の上流サービスにも適用されます。個人の Hyprsunset ファイルは保持されます。ユーザーの systemd オーバーライドが優先される場合があります。パッケージのインストールにより HOME に書き込まれることはありません。設定は `/displays/night_light` に、オーバーライドは `$XDG_RUNTIME_DIR/argvus/night-light/` に保存されます。詳細は `argvus config display night-light status` を参照してください。

セッションは、環境をインポートする前に、ログインユーザーの `$XDG_CONFIG_HOME/locale.conf`（デフォルトは `~/.config/locale.conf`）から LANG を読み込みます。これは TTY およびグラフィカルログインマネージャーに適用されます。言語の変更にはログアウトして再度ログインする必要があります。`/etc/locale.conf` は変更されません。

有効なユーザー`LANG`がない場合、ホストのロケールがポルトガル語であってもセッションは英語で開始されます。生成時には`en_US.UTF-8`を使用し、それ以外の場合は`C.UTF-8`を使用しますが、ユーザー構成は作成されません。ロケールの解決は構成の投影やデスクトップの起動より前に行われます。セッションは継承された`LC_ALL`をクリアし、`LANGUAGE`を含むsystemdユーザーおよびD-Busの起動環境の言語変数を置き換えます。 同じlocale.confからの地域カテゴリは維持されます。従来のARGVUS言語ファイルは無視されます。

セッションはHyprlandを開始する前に`$XDG_CONFIG_HOME/environment.d/20-timezone.conf`から個人のTZ設定を読み取り、それをユーザーサービスおよびD-Bus環境にインポートします。 zoneinfo名を検証し、ファイルを実行することはありません。新しいログイン時には、アプリケーションにタイムゾーンの変更が適用されます。


## ウィンドウボタンとアプリケーションバー

最小化は予約済みの`special:argvus-minimized`ワークスペースを使用します。そのワークスペースを手動で使用しないでください。`argvus windows service`プロセスは、識別情報、元のワークスペース/モニター、ジオメトリ、フルスクリーン/最大化およびピン状態を、コンポジタインスタンス固有のランタイムレジストリ内の`$XDG_RUNTIME_DIR/argvus`の下に記録します。記録はサービスの再起動や設定の再読み込みによっても保持されますが、コンポジタセッションを超えることはありません。ウィンドウを閉じると、その記録は削除されます。モニターが消えた場合、復元には利用可能な出力が使用されます。バーが存在しないか復旧に失敗した場合、新しい最小化はできません。復元に失敗した場合、記録と復旧バーは保持されます。

セッションは`argvus-windows.service`と`argvus-window-bar.service`を所有します。後者はWaybarの子プロセスをTileで休止状態に保ちます。hyprbarsプラグインは`argvus-hyprland`で同梱されており、x86_64上のHyprland 0.57.0 ABI向けにビルドされています。ユーザーのホームディレクトリではコンパイルされていません。コンポジタのABIが更新された場合、プラグインを再ビルドしてください。セッションは、中国語、日本語、韓国語を含む10のARGVUS言語すべてに選択されたUTF-8ロケールを伝播します。カタログの選択は`argvus i18n`によって処理されます。システムロケールの利用可能性とフォントフォールバックは別の要件です。
