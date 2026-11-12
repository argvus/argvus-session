---
title: جلسة رسومية
description:                                         .ﻲﻣﻮﺳﺭ ﻝﻮﺧﺩ ﻞﻴﺠﺴﺗ ﻖﻓﺪﺗ ﺮﺒﻋ ARGVUS ﺃﺪﺑﺍ
---

Hyprland.

بعد أن يصبح سطح المكتب جاهزًا، يتم تشغيل الجلسة

```sh
argvus sessionctl status
argvus sessionctl logs
argvus sessionctl reload
```

 لـ TTY وARGVUS Greeter ومديري تسجيل الدخول الآخرين. فهو يفتح صفحة الترحيب بمركز التحكم المتكامل ما لم يسجل التقدم لكل مستخدم argvus الجلسة أو الإكمال أو الفصل. يحفظ أول عرض ناجح argvus البدء في ~/.local/state/argvus/session.log، مما يمنع إعادة الفتح عند تسجيل الدخول لاحقًا. لا يعتمد ذلك على /run/argvus-greeter/session.log. الحسابات الموجودة بدون هذا السجل تتلقى أيضًا فتحًا تلقائيًا واحدًا. تسمح حالات الفشل قبل العرض بمحاولة أخرى لتسجيل الدخول التالي. يظل سجل الجلسة اليدوي متاحًا.

ينطبق على الجيل الذي كان ملتزما بالفعل. إذا كان أمر مثل `argvus session` أو `argvus start` أو `~/.local/state/argvus/session.log`/`/run/argvus-greeter/session.log` أو تغيير كتلة القياس عن بعد لعنصر واجهة المستخدم قد توقع التغيير للتو، فإن إعادة التحميل تستعيد المستهلكين المتأثرين من بيان الإسقاط بدلاً من العرض مرة أخرى. يتم المشروع فقط في حالة عدم وجود خطة معلقة، على سبيل المثال عند بدء الجلسة. إذا لم يتغير أي قسم ذي صلة بوقت التشغيل، فسيتم الخروج بنجاح دون إعادة تحميل Hyprland أو إعادة تشغيل الخدمات. عند وجود تغييرات، فإنه يعيد تطبيق تكامل الجلسة ويعيد تحميل المنضد وأسطح سطح المكتب المتأثرة فقط. يغطي البداية عملية إعادة التحميل فقط عند إعادة إنشاء السطح: إعادة تشغيل شريط Waybar (شريط المهام أو القياس عن بعد لعنصر واجهة المستخدم) أو لوحة التحكم، أو الخطة الاحتياطية `session.log`. يتم إعادة تحميل السمة واللكنة والتأثيرات والخطوط وتخطيط النافذة وتغييرات خلفية الشاشة في مكانها (`PATH` و`source_profile=false`، Hyprland's `hyprland-dialog`) بدونها، وإعادة التحميل بدون أي شيء للقيام به لا تظهر شيئًا. يتم تسلسل عمليات إعادة التحميل المتكررة ولا تؤدي الأقسام التي لم تتغير إلى إعادة تشغيل عملائها. `argvus sessionctl` هو اسم مستعار صريح لهذه العملية. عندما يتم عرضه، يكون رذاذ إعادة التحميل معتمًا أثناء تقدم العمل، لذلك لا يتم كشف سطح المكتب المتوسط. إنه ليس بديلاً لتسجيل الخروج عندما يجب إعادة تشغيل بيئة المنشئ أو تسجيل الدخول.




 للمسارات المثبتة والمستخدم. للمسارات المثبتة والمستخدم.(/docs/developer-guide/architecture/runtime-lifecycle/).

## ﻞﻴﻠﻟﺍ ءﻮﺿ

 `argvus-session.target`  `argvus-start`  `argvus-config.service`  `/usr/lib/argvus/greeter/handoff --send release`  `loginctl activate`  `argvus welcome --if-needed`  full  patch  set  accent  argvus config apply-theme  reload  systemctl --user mask argvus-secret-service.service  argvus sessionctl secret-service-status  argvus-taskbar-calendar  gnome-keyring  gnome-keyring  argvus-ssh-agent.service  SSH_AUTH_SOCK  secrets  gnome-keyring-daemon.service  argvus-secret-service.service  systemctl --user mask argvus-ssh-agent.service  SSH_AUTH_SOCK  SSH_AUTH_SOCK  $XDG_RUNTIME_DIR/ssh-agent.socket  openssh  argvus-ssh-agent.service  TERMINAL_EDITOR  VISUAL  EDITOR  ~/.cargo/bin  ~/.local/bin  PATH  argvus welcome  /etc/skel  ${XDG_STATE_HOME:-$HOME/.local/state}/argvus/welcome/progress.json  `opened`  `opened`  `${XDG_STATE_HOME:-$HOME/.local/state}/argvus/welcome/progress.json`  `/etc/skel`  `argvus welcome`  `PATH`  `~/.local/bin`  `~/.cargo/bin` `EDITOR`  `VISUAL`  `TERMINAL_EDITOR`  `argvus-ssh-agent.service`  `openssh`  `$XDG_RUNTIME_DIR/ssh-agent.socket`  `SSH_AUTH_SOCK`  `SSH_AUTH_SOCK`  `systemctl --user mask argvus-ssh-agent.service`  `argvus-secret-service.service`  `gnome-keyring-daemon.service`  `secrets`  `SSH_AUTH_SOCK`  `argvus-ssh-agent.service`  `gnome-keyring`  `gnome-keyring`  `argvus-taskbar-calendar`  `argvus sessionctl secret-service-status`  `systemctl --user mask argvus-secret-service.service`  `reload`  `argvus config apply-theme`  `accent`  `set`  `patch`  `full`  `argvus config theme-runtime consumers`  `wallpaper`  `/reload`  `apply-config`  `argvus sessionctl logs`  `argvus config validate`  يعتمد `argvus-session` على `hyprsunset>=0.4.0` ويشغّل خدمة المستخدم الأصلية عبر هدف الجلسة، من دون تفعيل خدمة إضافية. يطبّق `argvus-night-light-init.service` الحالة المحفوظة عند بدء الجلسة؛ ويقيّم المؤقّت الجداول المحلية الثابتة كل دقيقة وبعد تغييرات الساعة أو المنطقة الزمنية. عند إيقاف الجدولة، لا تغيّر الفحوص الدورية الحالة اليدوية. وتتبع الخدمة الأصلية `graphical-session.target` عند تسجيل الخروج.

 $XDG_RUNTIME_DIR/argvus/night-light/  /displays/night_light  /usr/share/argvus/session/config/night-light  XDG_CONFIG_DIRS  XDG_CONFIG_HOME  `--identity`  `XDG_CONFIG_HOME`  `XDG_CONFIG_DIRS`  `/usr/share/argvus/session/config/night-light`  `/displays/night_light`  `$XDG_RUNTIME_DIR/argvus/night-light/` `argvus config display night-light status`.



ARGVUS.




## ﻖﻴﺒﻄﺘﻟﺍ ﻂﻳﺮﺷﻭ





The session propagates the selected UTF-8 locale for all ten ARGVUS languages, including Chinese, Japanese and Korean. Catalog selection is handled by  argvus-hyprland  argvus-window-bar.service  argvus-windows.service  $XDG_RUNTIME_DIR/argvus  argvus windows service  special:argvus-minimized  $XDG_CONFIG_HOME/environment.d/20-timezone.conf  LANGUAGE  LC_ALL  C.UTF-8  en_US.UTF-8  LANG  /etc/locale.conf  ~/.config/locale.conf  `$XDG_CONFIG_HOME/locale.conf`  `~/.config/locale.conf`  `/etc/locale.conf`  `LANG`  `en_US.UTF-8`  `C.UTF-8`  `LC_ALL`  `LANGUAGE`  `$XDG_CONFIG_HOME/environment.d/20-timezone.conf`  `special:argvus-minimized`  `argvus windows service`  `$XDG_RUNTIME_DIR/argvus`  `argvus-windows.service`  `argvus-window-bar.service`  `argvus-hyprland` `argvus i18n`; system locale availability and font fallback are separate requirements.

                                ﺮﻈﻧﺍ .greetd ﻮﻫ ﻝﻮﺧﺪﻟﺍ ﻞﻴﺠﺴﺘﻟ ﻲﺿﺍﺮﺘﻓﻻ﻿ﺍ ﻞﻣﺎﻜﺘﻟﺍ[                                                                 ﻑﻮﻴﻀﻟﺍ ﻞﺒﻘﺘﺴﻣ](/docs/components/argvus-greeter/)                                                                             ﻭ[                                                          ﺔﺴﻠﺠﻟﺍ ﺕﻼ﻿ﻜﺸﻣ ﻑﺎﺸﻜﺘﺳﺍ](/docs/user-guide/troubleshooting/session-startup/).
                                        ﺮﻈﻧﺍ ،ﻞﻴﻐﺸﺘﻟﺍ ءﺪﺑ ﻞﺴﻠﺴﺗﻭ ﺔﻣﺪﺨﻟﺍ ﺔﻴﻜﻠﻤﻟ[                                                         ﻞﻴﻐﺸﺘﻟﺍ ﺖﻗﻭ ﺓﺎﻴﺣ ﺓﺭﻭﺩ](/docs/developer-guide/architecture/runtime-lifecycle/).
