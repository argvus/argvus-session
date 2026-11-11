---
title: TTY session
description: ARGVUS ۔ﮟﯾﺮﮐ ﻉﻭﺮﺷ ﺮﭘ ﺭﻮﻃ ﯽﺘﺳﺩ ﮯﺳ ﻞﻨﯿﻣﺮﭨ ﻞﺋﻮﭼﺭﻭ ﻮﮐ
---

TTY ﮟﯾﺮﮐ ﻉﻭﺮﺷ ﺡﺮﻃ ﺱﺍ ﻦﺸﯿﺳ ،ﺪﻌﺑ ﮯﮐ ﮯﻧﺮﮐ ﻥﺍ ﮒﻻ﻿ ﺮﭘ:

```sh
argvus --start-desktop
```

                                                  ﮯﮨ ﮧﻄﻘﻧ ﮧﻠﺧﺍﺩ ﯽﺘﺳﺩ ﮧﻘﻠﻌﺘﻣ ﮧﯾ`argvus session`. It uses the same `argvus start` and user-service lifecycle as a graphical login.

۔ﮟﯾﺮﮐ ﻝﺎﻤﻌﺘﺳﺍ argvus sessionctl logs ﺎﯾ `argvus sessionctl status`، `argvus sessionctl reload` ﮯﯿﻟ ﮯﮐ

##  `argvus sessionctl logs` `exec argvus-tty` ﺎﻧﺮﮐ ﺕﺮﺠﮨ ﮯﺳ

```sh
exec argvus --start-desktop
```

 PATH  exec argvus-tty  ~/.profile  /usr/bin  `argvus-tty`  `/usr/bin`  `~/.profile`  `exec argvus-tty`  `PATH` `argvus tty`                              ﮟﯾﺮﮐ ﭧﯾﮈ ﭖﺍ ﺎﯾ ﮟﯾﺩ ﺎﭩﮨ ﻮﮐ ﻦﺋﻻ﻿ ۔ﮯﮨ ﮧﻄﻘﻧ ﮧﻠﺧﺍﺩ ﯽﮩﯾ`~/.profile`, `~/.zprofile` or `~/.bash_profile` before the next login on a TTY.
