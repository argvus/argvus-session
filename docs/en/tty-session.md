---
title: TTY session
description: Start ARGVUS manually from a virtual terminal.
---

After logging in on a TTY, start the session with:

```sh
argvus --start-desktop
```

This is the supported manual entry point from `argvus session`. It uses the same `argvus start` and user-service lifecycle as a graphical login.

To inspect or restart the resulting session, use `argvus sessionctl status`, `argvus sessionctl reload` or `argvus sessionctl logs`.

## Migrating from `exec argvus-tty`

Earlier versions installed `argvus-tty` in `/usr/bin`, and some users started the session from `~/.profile` with `exec argvus-tty`. That file is now private and is no longer on `PATH`, so the line fails after the upgrade. Replace it with the supported entry point:

```sh
exec argvus --start-desktop
```

`argvus tty` is the same entry point. Remove or update the line in `~/.profile`, `~/.zprofile` or `~/.bash_profile` before the next login on a TTY.
