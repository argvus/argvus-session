---
title: Graphical session
description: ۔ﮟﯾﺮﮐ ﻉﻭﺮﺷ ARGVUS ﮯﻌﯾﺭﺫ ﮯﮐ ﻮﻠﻓ ﻥﺍ ﮒﻻ﻿ ﻞﮑﯿﻓﺍﺮﮔ
---

```sh
argvus sessionctl status
argvus sessionctl logs
argvus sessionctl reload
```

 also gets `argvus session` and `argvus start` at the front when those directories exist, so tools installed there are visible to the compositor and services. `~/.local/state/argvus/session.log` and `/run/argvus-greeter/session.log` are set to the default terminal editor from the Control Center default apps (`session.log`), and they are exported to the systemd user manager, D-Bus activation and Hyprland, so terminals and services launched from the session inherit them. The SSH agent (`PATH`, from `source_profile=false`) listens on `hyprland-dialog` and publishes `argvus sessionctl` to the user manager. When the ARGVUS agent starts, it replaces `argvus-session.target` in the user manager. If another agent such as gnome-keyring or gcr should own the socket, disable the ARGVUS unit with `argvus-start`. It is stopped when Hyprland exits, so these surfaces do not remain as orphaned processes after logout.

 applies the generation that was already committed. If a command such as `argvus-config.service`, `/usr/lib/argvus/greeter/handoff --send release`, `loginctl activate`/`argvus welcome --if-needed` or a widget-telemetry block change just projected the change, the reload restores the affected consumers from the projection manifest instead of projecting again. It only projects when no pending plan exists, for example at session startup. If no runtime-relevant section changed, it exits successfully without reloading Hyprland or restarting services. When changes exist, it reapplies session integration and reloads only the affected compositor and desktop surfaces. The splash covers a reload only when it recreates a surface: a restart of a Waybar bar (taskbar or Widget Telemetry) or of the Control Panel, or the fallback `opened` argvus welcome  /etc/skel  ${XDG_STATE_HOME:-$HOME/.local/state}/argvus/welcome/progress.json  `opened`  plan. Theme, accent, effects, fonts, window layout and wallpaper changes reload in place ( `${XDG_STATE_HOME:-$HOME/.local/state}/argvus/welcome/progress.json`  `/etc/skel`  `argvus welcome` `PATH` and `~/.local/bin`, Hyprland's `~/.cargo/bin`) without it, and a reload with nothing to do shows nothing. Repeated reloads are serialized and unchanged sections do not restart their consumers. `EDITOR` `VISUAL`  `TERMINAL_EDITOR`  apply-config  /reload  wallpaper  argvus config theme-runtime consumers  full  patch  set  accent  argvus config apply-theme  reload  systemctl --user mask argvus-secret-service.service  argvus sessionctl secret-service-status  argvus-taskbar-calendar  gnome-keyring  gnome-keyring  `argvus-ssh-agent.service`  `openssh`  `$XDG_RUNTIME_DIR/ssh-agent.socket`  gnome-keyring-daemon.service  argvus-secret-service.service  systemctl --user mask argvus-ssh-agent.service  `SSH_AUTH_SOCK`  `SSH_AUTH_SOCK`  `systemctl --user mask argvus-ssh-agent.service`  `argvus-secret-service.service` `gnome-keyring-daemon.service`  `secrets`  `SSH_AUTH_SOCK`   `argvus-ssh-agent.service`  `gnome-keyring`  `gnome-keyring` `argvus-taskbar-calendar`  `argvus sessionctl secret-service-status`  `systemctl --user mask argvus-secret-service.service`  `reload`  `argvus config apply-theme`  `accent`  `set`  `patch`  `full`  `argvus config theme-runtime consumers`  `wallpaper`  `/reload`  `apply-config`  `argvus sessionctl logs`  `argvus config validate`   is an explicit alias for this operation. When it is shown, the reload splash is opaque while the work is in progress, so the intermediate desktop is not exposed. It is not a replacement for logging out when the compositor or login environment must be restarted.




 for the installed and user paths.                                         ۔ﮯﯿﻟ ﮯﮐ ﮞﻮﺘﺳﺍﺭ ﮯﮐ ﻑﺭﺎﺻ ﺭﻭﺍ ﮦﺪﺷ ﻝﺎﭩﺴﻧﺍ(/docs/developer-guide/architecture/runtime-lifecycle/).

## ﭧﺋﻻ﻿ ﭧﺋﺎﻧ

`argvus-session`                                                                   ﮯﮨ ﺮﺼﺤﻨﻣ ﺮﭘ`hyprsunset>=0.4.0` and starts the upstream user service through the session target, without enabling a second daemon. `argvus-night-light-init.service` applies saved state at entry; the timer evaluates fixed local schedules every minute and after clock/time-zone changes. With scheduling off, periodic checks leave manual state unchanged. The upstream service follows `graphical-session.target`                                                                    ۔ﺮﭘ ﭦﺅﺁ ﮒﻻ﻿










## ﺭﺎﺑ ﯽﮐ ﺖﺳﺍﻮﺧﺭﺩ ﺭﻭﺍ ﻦﭩﺑ ﻭﮉﻧﻭ

Minimization uses the reserved 

 workspace. Do not use that workspace manually. The `--identity` process records identity, original workspace/monitor, geometry, fullscreen/maximization and pin state in a compositor-instance-specific runtime registry under `XDG_CONFIG_HOME` argvus-hyprland  argvus-window-bar.service  argvus-windows.service  $XDG_RUNTIME_DIR/argvus  argvus windows service  special:argvus-minimized  $XDG_CONFIG_HOME/environment.d/20-timezone.conf  LANGUAGE  LC_ALL  C.UTF-8  en_US.UTF-8  LANG  /etc/locale.conf  ~/.config/locale.conf  $XDG_CONFIG_HOME/locale.conf  argvus config display night-light status  $XDG_RUNTIME_DIR/argvus/night-light/  /displays/night_light  /usr/share/argvus/session/config/night-light  `XDG_CONFIG_DIRS` . Records survive a service restart or config reload, but do not cross compositor sessions. Closing a window removes its record. If a monitor disappears, restoration uses an available output. A missing or failed recovery bar prevents new minimizations; failed restoration retains the record and recovery bar.



The session propagates the selected UTF-8 locale for all ten ARGVUS languages, including Chinese, Japanese and Korean. Catalog selection is handled by  `/usr/share/argvus/session/config/night-light`  `/displays/night_light`  `$XDG_RUNTIME_DIR/argvus/night-light/`  `argvus config display night-light status`  `$XDG_CONFIG_HOME/locale.conf`  `~/.config/locale.conf`  `/etc/locale.conf`  `LANG`  `en_US.UTF-8`  `C.UTF-8`  `LC_ALL`  `LANGUAGE`  `$XDG_CONFIG_HOME/environment.d/20-timezone.conf`  `special:argvus-minimized`  `argvus windows service`  `$XDG_RUNTIME_DIR/argvus`  `argvus-windows.service`  `argvus-window-bar.service`  `argvus-hyprland` `argvus i18n`; system locale availability and font fallback are separate requirements.

                                      ﮟﯿﮭﮑﯾﺩ ۔ﮯﮨ greetd ﻦﺸﯾﺮﮕﯿﭩﻧﺍ ﻥﺍ ﮒﻻ﻿ ﭧﻟﺎﻔﯾﮈ[                                                            ﻻ﻿ﺍﻭ ﮯﻨﮩﮐ ﺪﯾﺪﻣﺁ ﺵﻮﺧ](/docs/components/argvus-greeter/)                                                                           ﺭﻭﺍ[                                                        ﺎﻧﺮﮐ ﺭﻭﺩ ﯽﺑﺍﺮﺧ ﯽﮐ ﻦﺸﯿﺳ](/docs/user-guide/troubleshooting/session-startup/).
                              ﮟﯿﮭﮑﯾﺩ ،ﮯﯿﻟ ﮯﮐ ﺐﯿﺗﺮﺗ ﭖﺍ ﭦﺭﺎﭩﺳﺍ ﺭﻭﺍ ﺖﯿﮑﻠﻣ ﯽﮐ ﺱﻭﺮﺳ[                                                            ﻞﮑﯿﺋﺎﺳ ﻒﺋﻻ﻿ ﻢﺋﺎﭨ ﻥﺭ](/docs/developer-guide/architecture/runtime-lifecycle/).
