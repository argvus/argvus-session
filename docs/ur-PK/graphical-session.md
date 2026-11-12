---
title: گرافیکل سیشن
description: ۔ﮟﯾﺮﮐ ﻉﻭﺮﺷ ARGVUS ﮯﻌﯾﺭﺫ ﮯﮐ ﻮﻠﻓ ﻥﺍ ﮒﻻ﻿ ﻞﮑﯿﻓﺍﺮﮔ
---

```sh
argvus sessionctl status
argvus sessionctl logs
argvus sessionctl reload
```

جب وہ ڈائریکٹریز موجود ہیں تو سامنے میں `argvus session` اور `argvus start` کو بھی ملتا ہے، لہذا وہاں نصب کردہ ٹولز کمپوزر اور سروسز کو دکھائی دیتے ہیں۔ `~/.local/state/argvus/session.log` اور `/run/argvus-greeter/session.log` کنٹرول سینٹر کے پہلے سے طے شدہ ایپس (`session.log`) سے ڈیفالٹ ٹرمینل ایڈیٹر پر سیٹ ہیں، اور انہیں systemd صارف مینیجر، D-Bus ایکٹیویشن اور Hyprland سے ان کی خدمات شروع کی جاتی ہیں، اس لیے ان کی خدمات کو سیشن میں شروع کیا جاتا ہے۔ SSH ایجنٹ (`PATH`، `source_profile=false` سے) `hyprland-dialog` پر سنتا ہے اور صارف مینیجر کو `argvus sessionctl` شائع کرتا ہے۔ جب ARGVUS ایجنٹ شروع ہوتا ہے، تو یہ صارف مینیجر میں `argvus-session.target` کی جگہ لے لیتا ہے۔ اگر کوئی اور ایجنٹ جیسا کہ gnome-keyring یا gcr ساکٹ کا مالک ہونا چاہیے تو ARGVUS یونٹ کو `argvus-start` کے ساتھ غیر فعال کریں۔ جب Hyprland باہر نکلتا ہے تو اسے روک دیا جاتا ہے، لہذا لاگ آؤٹ کے بعد یہ سطحیں یتیم عمل کے طور پر نہیں رہتی ہیں۔

 applies the generation that was already committed. If a command such as `argvus-config.service`, `/usr/lib/argvus/greeter/handoff --send release`, `loginctl activate`/`argvus welcome --if-needed` or a widget-telemetry block change just projected the change, the reload restores the affected consumers from the projection manifest instead of projecting again. It only projects when no pending plan exists, for example at session startup. If no runtime-relevant section changed, it exits successfully without reloading Hyprland or restarting services. When changes exist, it reapplies session integration and reloads only the affected compositor and desktop surfaces. The splash covers a reload only when it recreates a surface: a restart of a Waybar bar (taskbar or Widget Telemetry) or of the Control Panel, or the fallback `opened` argvus welcome  /etc/skel  ${XDG_STATE_HOME:-$HOME/.local/state}/argvus/welcome/progress.json  `opened`  plan. Theme, accent, effects, fonts, window layout and wallpaper changes reload in place ( `${XDG_STATE_HOME:-$HOME/.local/state}/argvus/welcome/progress.json`  `/etc/skel`  `argvus welcome` `PATH` and `~/.local/bin`, Hyprland's `~/.cargo/bin`) without it, and a reload with nothing to do shows nothing. Repeated reloads are serialized and unchanged sections do not restart their consumers. `EDITOR` `VISUAL`  `TERMINAL_EDITOR`  apply-config  /reload  wallpaper  argvus config theme-runtime consumers  full  patch  set  accent  argvus config apply-theme  reload  systemctl --user mask argvus-secret-service.service  argvus sessionctl secret-service-status  argvus-taskbar-calendar  gnome-keyring  gnome-keyring  `argvus-ssh-agent.service`  `openssh`  `$XDG_RUNTIME_DIR/ssh-agent.socket`  gnome-keyring-daemon.service  argvus-secret-service.service  systemctl --user mask argvus-ssh-agent.service  `SSH_AUTH_SOCK`  `SSH_AUTH_SOCK`  `systemctl --user mask argvus-ssh-agent.service`  `argvus-secret-service.service` `gnome-keyring-daemon.service`  `secrets`  `SSH_AUTH_SOCK`   `argvus-ssh-agent.service`  `gnome-keyring`  `gnome-keyring` `argvus-taskbar-calendar`  `argvus sessionctl secret-service-status`  `systemctl --user mask argvus-secret-service.service`  `reload`  `argvus config apply-theme`  `accent`  `set`  `patch`  `full`  `argvus config theme-runtime consumers`  `wallpaper`  `/reload`  `apply-config`  `argvus sessionctl logs`  `argvus config validate`   is an explicit alias for this operation. When it is shown, the reload splash is opaque while the work is in progress, so the intermediate desktop is not exposed. It is not a replacement for logging out when the compositor or login environment must be restarted.




 for the installed and user paths.                                         ۔ﮯﯿﻟ ﮯﮐ ﮞﻮﺘﺳﺍﺭ ﮯﮐ ﻑﺭﺎﺻ ﺭﻭﺍ ﮦﺪﺷ ﻝﺎﭩﺴﻧﺍ(/docs/developer-guide/architecture/runtime-lifecycle/).

## ﭧﺋﻻ﻿ ﭧﺋﺎﻧ

`argvus-session` ﮯﮨ ﺮﺼﺤﻨﻣ ﺮﭘ`hyprsunset>=0.4.0` اور سیشن ٹارگٹ کے ذریعے اپ اسٹریم یوزر سروس شروع کرتا ہے، بغیر کسی دوسرے ڈیمون کو فعال کیے۔ `argvus-night-light-init.service` داخلے پر محفوظ شدہ حالت کا اطلاق کرتا ہے۔ ٹائمر ہر منٹ اور گھڑی/ٹائم زون کی تبدیلیوں کے بعد مقررہ مقامی نظام الاوقات کا جائزہ لیتا ہے۔ شیڈولنگ بند ہونے کے ساتھ، وقتا فوقتا چیک دستی حالت میں کوئی تبدیلی نہیں کرتے۔ اپ اسٹریم سروس `graphical-session.target` ۔ﺮﭘ ﭦﺅﺁ ﮒﻻﮒ










## ﺭﺎﺑ ﯽﮐ ﺖﺳﺍﻮﺧﺭﺩ ﺭﻭﺍ ﻦﭩﺑ ﻭﮉﻧﻭ

مائنسائزیشن محفوظ استعمال کرتا ہے۔

 workspace. Do not use that workspace manually. The `--identity` process records identity, original workspace/monitor, geometry, fullscreen/maximization and pin state in a compositor-instance-specific runtime registry under `XDG_CONFIG_HOME` argvus-hyprland  argvus-window-bar.service  argvus-windows.service  $XDG_RUNTIME_DIR/argvus  argvus windows service  special:argvus-minimized  $XDG_CONFIG_HOME/environment.d/20-timezone.conf  LANGUAGE  LC_ALL  C.UTF-8  en_US.UTF-8  LANG  /etc/locale.conf  ~/.config/locale.conf  $XDG_CONFIG_HOME/locale.conf  argvus config display night-light status  $XDG_RUNTIME_DIR/argvus/night-light/  /displays/night_light  /usr/share/argvus/session/config/night-light  `XDG_CONFIG_DIRS` . Records survive a service restart or config reload, but do not cross compositor sessions. Closing a window removes its record. If a monitor disappears, restoration uses an available output. A missing or failed recovery bar prevents new minimizations; failed restoration retains the record and recovery bar.



The session propagates the selected UTF-8 locale for all ten ARGVUS languages, including Chinese, Japanese and Korean. Catalog selection is handled by  `/usr/share/argvus/session/config/night-light`  `/displays/night_light`  `$XDG_RUNTIME_DIR/argvus/night-light/`  `argvus config display night-light status`  `$XDG_CONFIG_HOME/locale.conf`  `~/.config/locale.conf`  `/etc/locale.conf`  `LANG`  `en_US.UTF-8`  `C.UTF-8`  `LC_ALL`  `LANGUAGE`  `$XDG_CONFIG_HOME/environment.d/20-timezone.conf`  `special:argvus-minimized`  `argvus windows service`  `$XDG_RUNTIME_DIR/argvus`  `argvus-windows.service`  `argvus-window-bar.service`  `argvus-hyprland` `argvus i18n`; system locale availability and font fallback are separate requirements.

                                      ﮟﯿﮭﮑﯾﺩ ۔ﮯﮨ greetd ﻦﺸﯾﺮﮕﯿﭩﻧﺍ ﻥﺍ ﮒﻻ﻿ ﭧﻟﺎﻔﯾﮈ[                                                            ﻻ﻿ﺍﻭ ﮯﻨﮩﮐ ﺪﯾﺪﻣﺁ ﺵﻮﺧ](/docs/components/argvus-greeter/)                                                                           ﺭﻭﺍ[                                                        ﺎﻧﺮﮐ ﺭﻭﺩ ﯽﺑﺍﺮﺧ ﯽﮐ ﻦﺸﯿﺳ](/docs/user-guide/troubleshooting/session-startup/).
                              ﮟﯿﮭﮑﯾﺩ ،ﮯﯿﻟ ﮯﮐ ﺐﯿﺗﺮﺗ ﭖﺍ ﭦﺭﺎﭩﺳﺍ ﺭﻭﺍ ﺖﯿﮑﻠﻣ ﯽﮐ ﺱﻭﺮﺳ[                                                            ﻞﮑﯿﺋﺎﺳ ﻒﺋﻻ﻿ ﻢﺋﺎﭨ ﻥﺭ](/docs/developer-guide/architecture/runtime-lifecycle/).
