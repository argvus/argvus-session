---
title: TTYセッション
description: 仮想端末から手動でARGVUSを起動してください。
---
TTYでログインした後、セッションを次のように開始します:

```sh
argvus --start-desktop
```
これは`argvus session`からのサポートされている手動エントリーポイントです。グラフィカルログインと同じ`argvus start`およびユーザーサービスのライフサイクルを使用します。

生成されたセッションを確認または再起動するには、`argvus sessionctl status`、`argvus sessionctl reload`、または`argvus sessionctl logs`を使用してください。

## `exec argvus-tty`からの移行

以前のバージョンでは、`argvus-tty`が`/usr/bin`にインストールされ、一部のユーザーはexec argvus-ttyを使用して`~/.profile`からセッションを開始していました。そのファイルは現在プライベートになっており、 `exec argvus-tty` `PATH`にはもう存在しないため、アップグレード後にその行は失敗します。サポートされているエントリーポイントに置き換えてください。

```sh
exec argvus --start-desktop
```
`argvus tty` は同じエントリーポイントです。次回 TTY でログインする前に、`~/.profile`、`~/.zprofile`、または `~/.bash_profile` の行を削除するか更新してください。
