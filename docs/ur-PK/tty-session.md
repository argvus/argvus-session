---
title: TTY سیشن
description: ARGVUS ۔ﮟﯾﺮﮐ ﻉﻭﺮﺷ ﺮﭘ ﺭﻮﻃ ﯽﺘﺳﺩ ﮯﺳ ﻞﻨﯿﻣﺮﭨ ﻞﺋﻮﭼﺭﻭ ﻮﮐ
---

TTY ﮟﯾﺮﮐ ﻉﻭﺮﺷ ﺡﺮﻃ ﺱﺍ ﻦﺸﯿﺳ ،ﺪﻌﺑ ﮯﮐ ﮯﻧﺮﮐ ﻥﺍ ﮒﻻ﻿ ﺮﭘ:

```sh
argvus --start-desktop
```

ﮯﮨ ﮧﻄﻘﻧ ﮧﻠﺧﺍﺩ ﯽﺘﺳﺩ ﮧﻘﻠﻌﺘﻣ ﮧﯾ`argvus session`. یہ وہی `argvus start` اور صارف سروس لائف سائیکل کو گرافیکل لاگ ان کے طور پر استعمال کرتا ہے۔

۔ﮟﯾﺮﮐ ﻝﺎﻤﻌﺘﺳﺍ argvus sessionctl logs ﺎﯾ `argvus sessionctl status`، `argvus sessionctl reload` ﮯﯿﻟ ﮯﮐ

##  `argvus sessionctl logs` `exec argvus-tty` ﺎﻧﺮﮐ ﺕﺮﺠﮨ ﮯﺳ

```sh
exec argvus --start-desktop
```

 PATH  exec argvus-tty  ~/.profile  /usr/bin  `argvus-tty`  `/usr/bin`  `~/.profile`  `exec argvus-tty`  `PATH` `argvus tty`                              ﮟﯾﺮﮐ ﭧﯾﮈ ﭖﺍ ﺎﯾ ﮟﯾﺩ ﺎﭩﮨ ﻮﮐ ﻦﺋﻻ﻿ ۔ﮯﮨ ﮧﻄﻘﻧ ﮧﻠﺧﺍﺩ ﯽﮩﯾ`~/.profile`, `~/.zprofile` or `~/.bash_profile` before the next login on a TTY.
