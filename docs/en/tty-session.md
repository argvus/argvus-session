---
title: TTY session
description: Start ARGVUS manually from a virtual terminal.
---

After logging in on a TTY, start the session with:

```sh
argvus --start-desktop
```

This is the supported manual entry point from `argvus-session`. It uses the same `argvus-start` and user-service lifecycle as a graphical login.

To inspect or restart the resulting session, use `argvus-sessionctl status`, `argvus-sessionctl reload` or `argvus-sessionctl logs`.
