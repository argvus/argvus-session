---
title: جلسة TTY
description:                                           .ﺔﻴﺿﺍﺮﺘﻓﺍ ﺔﻴﻓﺮﻃ ﻦﻣ ًﺎﻳﻭﺪﻳ ARGVUS ﺃﺪﺑﺍ
---

                                     :ـﺑ ﺔﺴﻠﺠﻟﺍ ﺃﺪﺑﺍ ،TTY ﻰﻠﻋ ﻝﻮﺧﺪﻟﺍ ﻞﻴﺠﺴﺗ ﺪﻌﺑ

```sh
argvus --start-desktop
```

هذه هي نقطة الإدخال اليدوية المدعومة من

```sh
exec argvus --start-desktop
```

. It uses the same

 and user-service lifecycle as a graphical login.

لفحص أو إعادة تشغيل الجلسة الناتجة، استخدم

,

 or argvus session.

## Migrating from

Earlier versions installed

 in

، وبدأ بعض المستخدمين الجلسة من `argvus session` باستخدام `argvus start`. أصبح هذا الملف الآن خاصًا ولم يعد موجودًا على `argvus sessionctl status`، لذا يفشل الخط بعد الترقية. استبدلها بنقطة الإدخال المدعومة:

 هي نفس نقطة الدخول قم بإزالة أو تحديث الخط الموجود

, `argvus sessionctl reload` or `argvus sessionctl logs` ~/.bash_profile  ~/.zprofile  ~/.profile  argvus tty  PATH  `exec argvus-tty`  ~/.profile  /usr/bin  `argvus-tty`   `/usr/bin`  `~/.profile` `exec argvus-tty` `PATH`  `argvus tty`  `~/.profile`  `~/.zprofile`  `~/.bash_profile`   before the next login on a TTY.
