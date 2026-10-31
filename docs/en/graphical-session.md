---
title: Graphical session
description: Start ARGVUS through a graphical login flow.
---

The graphical entry point is `argvus session`. It sets the session environment and delegates to `argvus start`, which imports it into the user manager, validates the packaged or user Hyprland Lua configuration, applies detected graphics compatibility settings, launches Hyprland and waits for compositor readiness.

Logs are written to `~/.local/state/argvus/session.log`. The greeter runs as its own user before login, so its pre-login output is kept in `/run/argvus-greeter/session.log` and appended to `session.log` when the session starts. Check this file first when a startup warning from Hyprland does not appear in the session log.

The session ensures that the shell `PATH` environment variable is set to a sensible default even when the login manager (such as greetd with `source_profile=false`) does not export one. This guarantees that utilities like `hyprland-dialog`, used by Hyprland at startup, are discoverable by child processes.

After Hyprland is ready, `argvus sessionctl` starts `argvus-session.target`. This target starts the taskbar, Control Panel, notifications, wallpaper, idle handling, clipboard, the SSH agent, the Secret Service provider and related services. A single loading spinner stays on screen from the login handoff until those services have started and the wallpaper and the taskbar are on screen (at most 1.5 seconds more). Before it launches Hyprland, `argvus-start` queues the configuration projection (`argvus-config.service`), which then runs during the compositor startup, and asks the greeter's DRM handoff surface to release the display (`/usr/lib/argvus/greeter/handoff --send release`); when that surface is running, it first activates the session with `loginctl activate`, so Hyprland never starts on a VT in the background. The session spinner then tells the surface to remove the overlay that hid Hyprland's first frames.

After the desktop is ready, the session runs `argvus welcome --if-needed` for TTY, ARGVUS Greeter and other login managers. It opens the integrated Control Center Welcome page unless per-user progress records `opened`, completion or dismissal. The first successful render saves `opened` in `${XDG_STATE_HOME:-$HOME/.local/state}/argvus/welcome/progress.json`, preventing reopening on later logins. It does not depend on `/etc/skel`. Existing accounts without that record also receive one automatic opening. Failures before rendering allow another attempt at the next login. Manual `argvus welcome` remains available.

`PATH` also gets `~/.local/bin` and `~/.cargo/bin` at the front when those directories exist, so tools installed there are visible to the compositor and services. `EDITOR` and `VISUAL` are set to the default terminal editor from the Control Center default apps (`TERMINAL_EDITOR`), and they are exported to the systemd user manager, D-Bus activation and Hyprland, so terminals and services launched from the session inherit them. The SSH agent (`argvus-ssh-agent.service`, from `openssh`) listens on `$XDG_RUNTIME_DIR/ssh-agent.socket` and publishes `SSH_AUTH_SOCK` to the user manager. When the ARGVUS agent starts, it replaces `SSH_AUTH_SOCK` in the user manager. If another agent such as gnome-keyring or gcr should own the socket, disable the ARGVUS unit with `systemctl --user mask argvus-ssh-agent.service`. It is stopped when Hyprland exits, so these surfaces do not remain as orphaned processes after logout.

The Secret Service provider is `argvus-secret-service.service`. It starts the upstream `gnome-keyring-daemon.service` with the `secrets` component only, so it does not serve SSH keys and `SSH_AUTH_SOCK` stays owned by `argvus-ssh-agent.service`. The unit is skipped when `gnome-keyring` is not installed. The package declares `gnome-keyring` as an optional dependency, and so does `argvus-taskbar-calendar`, which stores its CalDAV passwords there. ARGVUS does not change PAM, so the keyring is not unlocked at login: the first application that uses it asks for the keyring password, and the login collection is created then. Check the state with `argvus sessionctl secret-service-status`, which reports missing, stopped, running, locked or unlocked. To let KWallet or KeePassXC own the Secret Service instead, disable the ARGVUS unit with `systemctl --user mask argvus-secret-service.service`; the provider is stopped when the session stops.

The session also imports its Wayland and desktop-environment variables into the systemd user manager. To inspect or reload a running session:

```sh
argvus sessionctl status
argvus sessionctl logs
argvus sessionctl reload
```

`reload` applies the generation that was already committed. If a command such as `argvus config apply-theme`, `accent`, `set`/`patch` or a widget-telemetry block change just projected the change, the reload restores the affected consumers from the projection manifest instead of projecting again. It only projects when no pending plan exists, for example at session startup. If no runtime-relevant section changed, it exits successfully without reloading Hyprland or restarting services. When changes exist, it reapplies session integration and reloads only the affected compositor and desktop surfaces. The splash covers a reload only when it recreates a surface: a restart of a Waybar bar (taskbar or Widget Telemetry) or of the Control Panel, or the fallback `full` plan. Theme, accent, effects, fonts, window layout and wallpaper changes reload in place (`argvus config theme-runtime consumers` and `wallpaper`, Hyprland's `/reload`) without it, and a reload with nothing to do shows nothing. Repeated reloads are serialized and unchanged sections do not restart their consumers. `apply-config` is an explicit alias for this operation. When it is shown, the reload splash is opaque while the work is in progress, so the intermediate desktop is not exposed. It is not a replacement for logging out when the compositor or login environment must be restarted.

If the projection cannot be completed, the reload stops before restarting desktop surfaces. Check `argvus sessionctl logs` and run `argvus config validate` before trying again; this prevents a failed theme projection from leaving Waybar, notifications, or the Control Panel running with a stale mixture of themes.

The default login integration is greetd. See [Greeter](/docs/components/argvus-greeter/) and [session troubleshooting](/docs/user-guide/troubleshooting/session-startup/).

For service ownership and the startup sequence, see [Runtime lifecycle](/docs/developer-guide/architecture/runtime-lifecycle/).

## Night Light

`argvus-session` depends on `hyprsunset>=0.4.0` and starts the upstream user service through the session target, without enabling a second daemon. `argvus-night-light-init.service` applies saved state at entry; the timer evaluates fixed local schedules every minute and after clock/time-zone changes. With scheduling off, periodic checks leave manual state unchanged. The upstream service follows `graphical-session.target` at logout.

The packaged drop-in starts Hyprsunset with `--identity` and service-local `XDG_CONFIG_HOME`/`XDG_CONFIG_DIRS` pointing to `/usr/share/argvus/session/config/night-light`, whose config contains no native profiles. This avoids competing schedulers and startup at the upstream 6000 K default. It applies to the upstream service also outside ARGVUS while installed; personal Hyprsunset files are preserved. User systemd overrides can take precedence. No package install writes into HOME. Preferences are in `/displays/night_light`, overrides in `$XDG_RUNTIME_DIR/argvus/night-light/`; see `argvus config display night-light status`.

The session loads LANG from the logged-in user’s `$XDG_CONFIG_HOME/locale.conf` (default `~/.config/locale.conf`) before importing the environment. This applies to TTY and graphical login managers. Language changes require logging out and back in; `/etc/locale.conf` is not modified.

Without a valid user `LANG`, the session starts in English even if the host locale is Portuguese. It uses `en_US.UTF-8` when generated and `C.UTF-8` otherwise, without creating a user configuration. Locale resolution happens before configuration projection and desktop startup. The session clears inherited `LC_ALL` and replaces the language variables in the systemd user and D-Bus activation environments, including `LANGUAGE`. Regional categories from the same locale.conf are preserved. Legacy ARGVUS language files are ignored.

The session reads the personal TZ assignment from `$XDG_CONFIG_HOME/environment.d/20-timezone.conf` before starting Hyprland and imports it into the user service and D-Bus environments. It validates zoneinfo names and never executes the file. A new login applies timezone changes to applications.
