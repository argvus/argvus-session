---
title: TTY session
description:                                           .ﺔﻴﺿﺍﺮﺘﻓﺍ ﺔﻴﻓﺮﻃ ﻦﻣ ًﺎﻳﻭﺪﻳ ARGVUS ﺃﺪﺑﺍ
---

                                     :ـﺑ ﺔﺴﻠﺠﻟﺍ ﺃﺪﺑﺍ ،TTY ﻰﻠﻋ ﻝﻮﺧﺪﻟﺍ ﻞﻴﺠﺴﺗ ﺪﻌﺑ

```sh
argvus --start-desktop
```

This is the supported manual entry point from 

```sh
exec argvus --start-desktop
```

. It uses the same 

 and user-service lifecycle as a graphical login.

To inspect or restart the resulting session, use 

, 

 or argvus session.

## Migrating from 

Earlier versions installed 

 in 

, and some users started the session from `argvus session` with `argvus start`. That file is now private and is no longer on `argvus sessionctl status`, so the line fails after the upgrade. Replace it with the supported entry point:

 is the same entry point. Remove or update the line in 

, `argvus sessionctl reload` or `argvus sessionctl logs` ~/.bash_profile  ~/.zprofile  ~/.profile  argvus tty  PATH  `exec argvus-tty`  ~/.profile  /usr/bin  `argvus-tty`   `/usr/bin`  `~/.profile` `exec argvus-tty` `PATH`  `argvus tty`  `~/.profile`  `~/.zprofile`  `~/.bash_profile`   before the next login on a TTY.
