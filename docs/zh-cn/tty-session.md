---
title: TTY 会话
description: 从虚拟终端手动启动 ARGVUS。
---
在 TTY 登录后，使用以下方式启动会话：

```sh
argvus --start-desktop
```
这是来自 `argvus session` 的支持手动入口。它使用与图形登录相同的 `argvus start` 和用户服务生命周期。

要检查或重新启动生成的会话，请使用 `argvus sessionctl status`、`argvus sessionctl reload` 或 `argvus sessionctl logs`。

## 从 `exec argvus-tty` 迁移

早期版本在 /usr/bin 中安装了 `argvus-tty`，并且一些用户使用 `/usr/bin` 从 `~/.profile` 启动会话。该文件现在是私有的，并且不再位于  `exec argvus-tty` `PATH`，因此升级后该行会失败。请用支持的入口替换它：

```sh
exec argvus --start-desktop
```
`argvus tty` 是相同的入口点。在下一次通过 TTY 登录之前，请在 `~/.profile`、`~/.zprofile` 或 `~/.bash_profile` 中删除或更新该行。
