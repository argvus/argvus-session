---
title: Graphical session
description: Start ARGVUS through a graphical login flow.
---

The graphical entry point is `/usr/bin/argvus-session`. It imports the session environment and delegates to `argvus-start`, which validates the packaged or user Hyprland Lua configuration, applies detected graphics compatibility settings, launches Hyprland and waits for compositor readiness.

Logs are written to `~/.local/state/argvus/session.log`. The greeter runs as its own user before login, so its pre-login output is kept in `/run/argvus-greeter/session.log` and appended to `session.log` when the session starts. Check this file first when a startup warning from Hyprland does not appear in the session log.

The session ensures that the shell `PATH` environment variable is set to a sensible default even when the login manager (such as greetd with `source_profile=false`) does not export one. This guarantees that utilities like `hyprland-dialog`, used by Hyprland at startup, are discoverable by child processes.

After Hyprland is ready, `argvus-sessionctl` starts `argvus-session.target`. This target starts the taskbar, Control Panel, notifications, wallpaper, idle handling, clipboard, the SSH agent and related services.

`PATH` also gets `~/.local/bin` and `~/.cargo/bin` at the front when those directories exist, so tools installed there are visible to the compositor and services. `EDITOR` and `VISUAL` are set to the default terminal editor from the Control Center default apps (`TERMINAL_EDITOR`), and they are exported to the systemd user manager, D-Bus activation and Hyprland, so terminals and services launched from the session inherit them. The SSH agent (`argvus-ssh-agent.service`, from `openssh`) listens on `$XDG_RUNTIME_DIR/ssh-agent.socket` and publishes `SSH_AUTH_SOCK` to the user manager. When the ARGVUS agent starts, it replaces `SSH_AUTH_SOCK` in the user manager. If another agent such as gnome-keyring or gcr should own the socket, disable the ARGVUS unit with `systemctl --user mask argvus-ssh-agent.service`. It is stopped when Hyprland exits, so these surfaces do not remain as orphaned processes after logout.

The session also imports its Wayland and desktop-environment variables into the systemd user manager. To inspect or reload a running session:

```sh
argvus-sessionctl status
argvus-sessionctl logs
argvus-sessionctl reload
```

`reload` applies the generation that was already committed. If a command such as `argvus-config apply-theme`, `accent`, `set`/`patch` or a widget-telemetry block change just projected the change, the reload restores the affected consumers from the projection manifest instead of projecting again. It only projects when no pending plan exists, for example at session startup. If no runtime-relevant section changed, it exits successfully without reloading Hyprland, restarting services or showing the splash. When changes exist, it reapplies session integration and reloads only the affected compositor and desktop surfaces. Repeated reloads are serialized and unchanged sections do not restart their consumers. `apply-config` is an explicit alias for this operation. The direct reload overlay is static and opaque while the work is in progress, so the intermediate desktop is not exposed. It is not a replacement for logging out when the compositor or login environment must be restarted.

If the projection cannot be completed, the reload stops before restarting desktop surfaces. Check `argvus-sessionctl logs` and run `argvus-config validate` before trying again; this prevents a failed theme projection from leaving Waybar, notifications, or the Control Panel running with a stale mixture of themes.

The default login integration is greetd. See [Greeter](/docs/argvus-greeter/) and [session troubleshooting](/docs/user-guide/troubleshooting/session-startup/).

For service ownership and the startup sequence, see [Runtime lifecycle](../../developer-guide/architecture/runtime-lifecycle/).
