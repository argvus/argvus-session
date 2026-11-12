---
title: 图形会话
description: 通过图形登录流程启动 ARGVUS。
---
图形入口点是 `argvus session`。它设置会话环境并委托给 `argvus start`，后者将其导入用户管理器，验证打包的或用户的 Hyprland Lua 配置，应用检测到的图形兼容性设置，启动 Hyprland 并等待合成器准备就绪。

日志写入 `~/.local/state/argvus/session.log`。迎宾界面在登录之前作为其自己的用户运行，因此其登录前输出保存在 `/run/argvus-greeter/session.log` 中，并在会话开始时附加到 `session.log`。当 Hyprland 的启动警告未出现在会话日志中时，应首先检查此文件。

会话确保即使登录管理器（例如带有 source_profile=false 的 greetd）未导出 shell `PATH` 环境变量，也会将其设置为合理的默认值。这保证了像  `source_profile=false` `hyprland-dialog` 这样的实用程序（Hyprland 启动时使用）可以被子进程发现。

在 Hyprland 准备好之后，`argvus sessionctl` 会启动 `argvus-session.target`。该目标会启动任务栏、控制面板、通知、壁纸、空闲处理、剪贴板、SSH 代理、Secret Service 提供程序及相关服务。从登录移交开始到这些服务启动并且壁纸和任务栏显示在屏幕上（最多再 1.5 秒）期间，屏幕上会保持一个加载旋转图标。在启动 Hyprland 之前，`argvus-start` 会排队配置投影（`argvus-config.service`），该配置在合成器启动期间运行，并要求迎宾程序的 DRM 移交表面释放显示器（`/usr/lib/argvus/greeter/handoff --send release`）；当该表面运行时，它会先使用 `loginctl activate` 激活会话，因此 Hyprland 从不在后台的 VT 上启动。然后会话旋转图标会告诉表面移除隐藏 Hyprland 第一帧的覆盖层。

桌面准备就绪后，会话为 TTY、ARGVUS Greeter 和其他登录管理器运行 `argvus welcome --if-needed`。除非每用户的进度记录 `opened`、完成或关闭，否则它会打开集成控制中心欢迎页面。首次成功渲染会将 `opened` 保存在 `${XDG_STATE_HOME:-$HOME/.local/state}/argvus/welcome/progress.json` 中，从而防止以后登录时再次打开。它不依赖于 `/etc/skel`。现有账户如果没有该记录，也会自动打开一次。在渲染之前的失败允许下次登录时再次尝试。手动 `argvus welcome` 仍然可用。

`PATH` 还会在这些目录存在时将 `~/.local/bin` 和 `~/.cargo/bin` 放在前面，因此安装在这些目录中的工具对于合成器和服务是可见的。`EDITOR` 和 `VISUAL` 被设置为来自控制中心默认应用程序 (`TERMINAL_EDITOR`) 的默认终端编辑器，并且它们被导出到 systemd 用户管理器、D-Bus 激活和 Hyprland，因此从会话启动的终端和服务会继承它们。SSH 代理 (`argvus-ssh-agent.service`，来自 `openssh`) 监听 `$XDG_RUNTIME_DIR/ssh-agent.socket`，并向用户管理器发布 `SSH_AUTH_SOCK`。当 ARGVUS 代理启动时，它会替换用户管理器中的 `SSH_AUTH_SOCK`。如果其他代理（如 gnome-keyring 或 gcr）应该拥有该套接字，请使用 `systemctl --user mask argvus-ssh-agent.service` 禁用 ARGVUS 单元。当 Hyprland 退出时，它会停止，因此这些界面在注销后不会作为孤立进程残留。

秘密服务提供者是 `argvus-secret-service.service`。它仅使用 secrets 组件启动上游的 `gnome-keyring-daemon.service`，因此不提供 SSH 密钥，并且  `secrets` `SSH_AUTH_SOCK` 仍由 `argvus-ssh-agent.service` 拥有。当未安装 `gnome-keyring` 时，该单元会被跳过。该软件包声明 `gnome-keyring` 为可选依赖项，`argvus-taskbar-calendar` 也是如此，它将其 CalDAV 密码存储在那里。ARGVUS 不会更改 PAM，因此登录时不会解锁钥匙环：第一个使用它的应用会要求输入钥匙环密码，并在那时创建登录集合。使用 `argvus sessionctl secret-service-status` 检查状态，该命令报告缺失、已停止、运行中、已锁定或已解锁。要让 KWallet 或 KeePassXC 拥有秘密服务，需使用 `systemctl --user mask argvus-secret-service.service` 禁用 ARGVUS 单元；会话停止时提供者也会停止。

该会话还将其 Wayland 和桌面环境变量导入到 systemd 用户管理器中。要检查或重新加载正在运行的会话：

```sh
argvus sessionctl status
argvus sessionctl logs
argvus sessionctl reload
```

`reload` 应用已提交的生成。如果像 `argvus config apply-theme`、`accent`、`set`/`patch` 这样的命令，或小部件遥测块更改只是投影了更改，则重新加载会从投影清单中恢复受影响的消费者，而不是再次投影。只有在没有待处理计划存在时才进行投影，例如在会话启动时。如果没有运行时相关的部分发生改变，它会成功退出，而不会重新加载 Hyprland 或重启服务。当存在更改时，它会重新应用会话集成，并仅重新加载受影响的合成器和桌面表面。启动画面只在重新创建表面时覆盖重新加载：例如重新启动 Waybar 栏（任务栏或小部件遥测）或控制面板，或回退 `full` 计划。主题、强调色、效果、字体、窗口布局和壁纸的更改会就地重新加载（`argvus config theme-runtime consumers` 和 `wallpaper`，Hyprland 的 `/reload`），无需启动画面。 而且在没有要做的事情时重新加载不会显示任何内容。重复的重新加载是串行进行的，未更改的部分不会重新启动它们的消费者。`apply-config` 是此操作的显式别名。当它显示时，重新加载的启动画面在工作进行时是不透明的，因此不会暴露中间桌面。这并不能替代在必须重启合成器或登录环境时退出登录。

如果投影无法完成，重新加载会在重启桌面表面之前停止。请检查 `argvus sessionctl logs` 并在再次尝试之前运行 `argvus config validate`；这可以防止失败的主题投影导致 Waybar、通知或控制面板在使用过时的主题混合下运行。

默认登录集成为 greetd。请参见 [Greeter](/docs/components/argvus-greeter/) 和 [session troubleshooting](/docs/user-guide/troubleshooting/session-startup/)。

有关服务所有权和启动顺序，请参见 [Runtime lifecycle](/docs/developer-guide/architecture/runtime-lifecycle/)。

## 夜灯

`argvus-session` 依赖于 `hyprsunset>=0.4.0`，并通过会话目标启动上游用户服务，而不启用第二个守护进程。`argvus-night-light-init.service` 在入口处应用已保存的状态；计时器每分钟以及在时钟/时区更改后评估固定的本地计划。当调度关闭时，周期性检查不会更改手动状态。上游服务在注销时遵循 `graphical-session.target`。

打包的即插即用程序使用 `--identity` 启动 Hyprsunset，并且本地服务 `XDG_CONFIG_HOME`/`XDG_CONFIG_DIRS` 指向 `/usr/share/argvus/session/config/night-light`，其配置不包含本地配置文件。这可以避免调度器冲突并在上游 6000 K 默认值启动。它也适用于 ARGVUS 外的上游服务在安装期间；个人 Hyprsunset 文件会被保留。用户的 systemd 覆盖可以优先。没有包安装会写入 HOME。偏好设置在 `/displays/night_light`，覆盖在 `$XDG_RUNTIME_DIR/argvus/night-light/`；参见 `argvus config display night-light status`。

会话从已登录用户的 `$XDG_CONFIG_HOME/locale.conf`（默认值 `~/.config/locale.conf`）加载 LANG，然后再导入环境。这适用于 TTY 和图形登录管理器。语言更改需要注销后重新登录；`/etc/locale.conf` 不会被修改。

如果没有有效的用户 `LANG`，即使主机区域设置为葡萄牙语，会议也会以英语启动。生成时使用 `en_US.UTF-8`，否则使用 `C.UTF-8`，而不会创建用户配置。区域设置解析发生在配置投影和桌面启动之前。会话会清除继承的 `LC_ALL`，并替换 systemd 用户和 D-Bus 激活环境中的语言变量，包括 `LANGUAGE`。来自同一 locale.conf 的区域类别会被保留。旧的 ARGVUS 语言文件会被忽略。

会话在启动 Hyprland 之前会从 `$XDG_CONFIG_HOME/environment.d/20-timezone.conf` 读取个人 TZ 分配，并将其导入用户服务和 D-Bus 环境中。它会验证 zoneinfo 名称，但从不执行该文件。新的登录会将时区更改应用到应用程序中。


## 窗口按钮和应用程序栏

最小化使用保留的 `special:argvus-minimized` 工作区。请勿手动使用该工作区。`argvus windows service` 进程在特定合成器实例的运行时注册表中记录身份、原始工作区/显示器、几何形状、全屏/最大化和固定状态，注册表位于 `$XDG_RUNTIME_DIR/argvus` 下。记录在服务重启或配置重新加载后仍然存在，但不会跨合成器会话。关闭窗口会删除其记录。如果显示器消失，恢复将使用可用的输出。缺失或恢复条失败会阻止新的最小化；恢复失败会保留记录和恢复条。

会话拥有 `argvus-windows.service` 和 `argvus-window-bar.service`。后者保持其 Waybar 子项在 Tile 中处于休眠状态。hyprbars 插件由 `argvus-hyprland` 提供，构建于 Hyprland 0.57.0 的 x86_64 ABI；它并未在用户主目录中编译。若合成器 ABI 更新，请重新构建该插件。该会话为所有十种 ARGVUS 语言传播所选的 UTF-8 语言环境，包括中文、日文和韩文。目录选择由 `argvus i18n` 处理；系统语言环境的可用性和字体回退是单独的要求。
