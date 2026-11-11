---
title: Graphical session
description:                                         .ﻲﻣﻮﺳﺭ ﻝﻮﺧﺩ ﻞﻴﺠﺴﺗ ﻖﻓﺪﺗ ﺮﺒﻋ ARGVUS ﺃﺪﺑﺍ
---

Hyprland.

After the desktop is ready, the session runs 

```sh
argvus sessionctl status
argvus sessionctl logs
argvus sessionctl reload
```

 for TTY, ARGVUS Greeter and other login managers. It opens the integrated Control Center Welcome page unless per-user progress records argvus session, completion or dismissal. The first successful render saves argvus start in ~/.local/state/argvus/session.log, preventing reopening on later logins. It does not depend on /run/argvus-greeter/session.log. Existing accounts without that record also receive one automatic opening. Failures before rendering allow another attempt at the next login. Manual session.log remains available.

 applies the generation that was already committed. If a command such as `argvus session`, `argvus start`, `~/.local/state/argvus/session.log`/`/run/argvus-greeter/session.log` or a widget-telemetry block change just projected the change, the reload restores the affected consumers from the projection manifest instead of projecting again. It only projects when no pending plan exists, for example at session startup. If no runtime-relevant section changed, it exits successfully without reloading Hyprland or restarting services. When changes exist, it reapplies session integration and reloads only the affected compositor and desktop surfaces. The splash covers a reload only when it recreates a surface: a restart of a Waybar bar (taskbar or Widget Telemetry) or of the Control Panel, or the fallback `session.log` plan. Theme, accent, effects, fonts, window layout and wallpaper changes reload in place (`PATH` and `source_profile=false`, Hyprland's `hyprland-dialog`) without it, and a reload with nothing to do shows nothing. Repeated reloads are serialized and unchanged sections do not restart their consumers. `argvus sessionctl` is an explicit alias for this operation. When it is shown, the reload splash is opaque while the work is in progress, so the intermediate desktop is not exposed. It is not a replacement for logging out when the compositor or login environment must be restarted.




 for the installed and user paths. for the installed and user paths.(/docs/developer-guide/architecture/runtime-lifecycle/).

## ﻞﻴﻠﻟﺍ ءﻮﺿ

 `argvus-session.target`  `argvus-start`  `argvus-config.service`  `/usr/lib/argvus/greeter/handoff --send release`  `loginctl activate`  `argvus welcome --if-needed`  full  patch  set  accent  argvus config apply-theme  reload  systemctl --user mask argvus-secret-service.service  argvus sessionctl secret-service-status  argvus-taskbar-calendar  gnome-keyring  gnome-keyring  argvus-ssh-agent.service  SSH_AUTH_SOCK  secrets  gnome-keyring-daemon.service  argvus-secret-service.service  systemctl --user mask argvus-ssh-agent.service  SSH_AUTH_SOCK  SSH_AUTH_SOCK  $XDG_RUNTIME_DIR/ssh-agent.socket  openssh  argvus-ssh-agent.service  TERMINAL_EDITOR  VISUAL  EDITOR  ~/.cargo/bin  ~/.local/bin  PATH  argvus welcome  /etc/skel  ${XDG_STATE_HOME:-$HOME/.local/state}/argvus/welcome/progress.json  `opened`  `opened`  `${XDG_STATE_HOME:-$HOME/.local/state}/argvus/welcome/progress.json`  `/etc/skel`  `argvus welcome`  `PATH`  `~/.local/bin`  `~/.cargo/bin` `EDITOR`  `VISUAL`  `TERMINAL_EDITOR`  `argvus-ssh-agent.service`  `openssh`  `$XDG_RUNTIME_DIR/ssh-agent.socket`  `SSH_AUTH_SOCK`  `SSH_AUTH_SOCK`  `systemctl --user mask argvus-ssh-agent.service`  `argvus-secret-service.service`  `gnome-keyring-daemon.service`  `secrets`  `SSH_AUTH_SOCK`  `argvus-ssh-agent.service`  `gnome-keyring`  `gnome-keyring`  `argvus-taskbar-calendar`  `argvus sessionctl secret-service-status`  `systemctl --user mask argvus-secret-service.service`  `reload`  `argvus config apply-theme`  `accent`  `set`  `patch`  `full`  `argvus config theme-runtime consumers`  `wallpaper`  `/reload`  `apply-config`  `argvus sessionctl logs`  `argvus config validate`  يعتمد `argvus-session` على `hyprsunset>=0.4.0` ويشغّل خدمة المستخدم الأصلية عبر هدف الجلسة، من دون تفعيل خدمة إضافية. يطبّق `argvus-night-light-init.service` الحالة المحفوظة عند بدء الجلسة؛ ويقيّم المؤقّت الجداول المحلية الثابتة كل دقيقة وبعد تغييرات الساعة أو المنطقة الزمنية. عند إيقاف الجدولة، لا تغيّر الفحوص الدورية الحالة اليدوية. وتتبع الخدمة الأصلية `graphical-session.target` عند تسجيل الخروج.

 $XDG_RUNTIME_DIR/argvus/night-light/  /displays/night_light  /usr/share/argvus/session/config/night-light  XDG_CONFIG_DIRS  XDG_CONFIG_HOME  `--identity`  `XDG_CONFIG_HOME`  `XDG_CONFIG_DIRS`  `/usr/share/argvus/session/config/night-light`  `/displays/night_light`  `$XDG_RUNTIME_DIR/argvus/night-light/` `argvus config display night-light status`.



ARGVUS.




## ﻖﻴﺒﻄﺘﻟﺍ ﻂﻳﺮﺷﻭ





The session propagates the selected UTF-8 locale for all ten ARGVUS languages, including Chinese, Japanese and Korean. Catalog selection is handled by  argvus-hyprland  argvus-window-bar.service  argvus-windows.service  $XDG_RUNTIME_DIR/argvus  argvus windows service  special:argvus-minimized  $XDG_CONFIG_HOME/environment.d/20-timezone.conf  LANGUAGE  LC_ALL  C.UTF-8  en_US.UTF-8  LANG  /etc/locale.conf  ~/.config/locale.conf  `$XDG_CONFIG_HOME/locale.conf`  `~/.config/locale.conf`  `/etc/locale.conf`  `LANG`  `en_US.UTF-8`  `C.UTF-8`  `LC_ALL`  `LANGUAGE`  `$XDG_CONFIG_HOME/environment.d/20-timezone.conf`  `special:argvus-minimized`  `argvus windows service`  `$XDG_RUNTIME_DIR/argvus`  `argvus-windows.service`  `argvus-window-bar.service`  `argvus-hyprland` `argvus i18n`; system locale availability and font fallback are separate requirements.

                                ﺮﻈﻧﺍ .greetd ﻮﻫ ﻝﻮﺧﺪﻟﺍ ﻞﻴﺠﺴﺘﻟ ﻲﺿﺍﺮﺘﻓﻻ﻿ﺍ ﻞﻣﺎﻜﺘﻟﺍ[                                                                 ﻑﻮﻴﻀﻟﺍ ﻞﺒﻘﺘﺴﻣ](/docs/components/argvus-greeter/)                                                                             ﻭ[                                                          ﺔﺴﻠﺠﻟﺍ ﺕﻼ﻿ﻜﺸﻣ ﻑﺎﺸﻜﺘﺳﺍ](/docs/user-guide/troubleshooting/session-startup/).
                                        ﺮﻈﻧﺍ ،ﻞﻴﻐﺸﺘﻟﺍ ءﺪﺑ ﻞﺴﻠﺴﺗﻭ ﺔﻣﺪﺨﻟﺍ ﺔﻴﻜﻠﻤﻟ[                                                         ﻞﻴﻐﺸﺘﻟﺍ ﺖﻗﻭ ﺓﺎﻴﺣ ﺓﺭﻭﺩ](/docs/developer-guide/architecture/runtime-lifecycle/).
