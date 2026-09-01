# Argvus Session

Argvus Session provides the lifecycle and supervision infrastructure for the
Argvus Desktop Environment.

It ships the graphical entrypoints, session controller, and systemd user units
that bind ARGVUS desktop processes to one explicit session target. The main
`argvus` package still owns desktop configuration, themes, Hyprland config,
Quickshell UI, Waybar/Dunst configs, and feature scripts.

## Flow

```text
greetd / display manager / TTY
        |
        v
argvus-session
        |
        |-- prepare ARGVUS/XDG environment
        |-- synchronize systemd and DBus activation environment
        v
argvus-start
        |
        |-- verify user Hyprland config or packaged fallback
        |-- apply VM workarounds
        v
Hyprland
        |
        v
hyprland.start readiness bridge
        |
        v
argvus-session.target
        |
        |-- argvus-session-prepare.service
        |-- argvus-wallpaper.service
        |-- argvus-shell.service
        |-- argvus-waybar-taskbar.service
        |-- argvus-waybar-sysinfo.service
        |-- argvus-dunst.service
        |-- argvus-hypridle.service
        |-- argvus-polkit.service
        |-- argvus-snappy-switcher.service
        |-- argvus-clipboard-text.service
        |-- argvus-clipboard-image.service
        `-- argvus-keyboard-layout.service
```

Hyprland remains launched by `argvus-start` instead of being moved under
`systemd --user` directly. This preserves the current greetd/display-manager/TTY
paths, `start-hyprland` compatibility, Lua config verification, VM detection,
user config override, and packaged fallback behavior. The Hyprland Lua
`hyprland.start` event is only a readiness bridge that runs
`argvus-sessionctl ready`.

When Hyprland exits, `argvus-start` stops `argvus-session.target`, asks
`graphical-session.target` to stop if active, then exits with Hyprland's exit
status. Services with `PartOf=argvus-session.target graphical-session.target`
are stopped as part of logout so ARGVUS-owned panels, daemons, applets, and
clipboard watchers do not survive the session.

## Commands

```sh
argvus-sessionctl start
argvus-sessionctl stop
argvus-sessionctl restart
argvus-sessionctl reload
argvus-sessionctl status
argvus-sessionctl logs
```

Useful component restarts:

```sh
argvus-sessionctl restart waybar
argvus-sessionctl restart wallpaper
argvus-sessionctl restart dunst shell snappy-switcher
argvus-sessionctl restart clipboard keyboard-layout blueman-applet
```

`reload` re-applies mutable ARGVUS state through the `argvus` package's
one-shot scripts, reloads Hyprland, reapplies monitor changes, and restarts only
the services that need fresh configuration.

`argvus-blueman-applet.service` is still installed for users who want Blueman's
legacy tray applet, but it is no longer pulled into the default session target.
Bluetooth power/status is surfaced by the `argvus` Waybar module and Quickshell
control-panel card.

## Environment

`argvus-session` and `argvus-start` preserve the existing ARGVUS environment:

- `ARGVUS_CONFIG_HOME`
- `ARGVUS_SYSTEM_CONFIG`
- `XDG_CONFIG_HOME`
- `XDG_CONFIG_DIRS`
- `XDG_CURRENT_DESKTOP=Hyprland`
- `XDG_SESSION_DESKTOP=Hyprland`
- `XDG_SESSION_TYPE=wayland`
- `DESKTOP_SESSION=argvus`
- `GDMSESSION=argvus`

`argvus-sessionctl import-environment` synchronizes these values, plus Wayland,
Hyprland, Qt, cursor, and DBus variables, into `systemd --user` and DBus
activation with `systemctl --user import-environment` and
`dbus-update-activation-environment --systemd` when available.

## Portals And PolicyKit

XDG portals are not manually killed or restarted by ARGVUS. They remain owned by
their upstream DBus/systemd activation path.

PolicyKit is integrated through `argvus-polkit.service`, which requests the
upstream `hyprpolkitagent.service` when that user unit is installed and stops it
with the ARGVUS session. ARGVUS does not start a second agent instance.

## Layout

```text
bin/
  argvus-session
  argvus-start
  argvus-tty
  argvus-sessionctl
usr/
  lib/
    systemd/
      user/
        argvus-session.target
        argvus-*.service
  share/
    wayland-sessions/
      argvus.desktop
```

## Installation

```sh
make install
```

Use `DESTDIR` for packaging:

```sh
make DESTDIR="$pkgdir" PREFIX=/usr install
```

The package installs user units into `/usr/lib/systemd/user`. Users can override
them with normal systemd drop-ins under `~/.config/systemd/user/<unit>.d/`.
Services are not enabled globally; logging into ARGVUS starts
`argvus-session.target` explicitly.

## Logs

```sh
journalctl --user -u argvus-session.target -u 'argvus-*.service'
journalctl --user -u argvus-waybar-taskbar.service
journalctl --user -u argvus-shell.service
```

The bootstrap log remains at:

```text
${XDG_STATE_HOME:-$HOME/.local/state}/argvus/session.log
```

## Release Flow

Tag pushes build a signed Arch package and publish it to the shared
`argvus/packages` repository. GitHub Releases are not used for package
distribution.

## Related Repositories

- https://github.com/argvus/argvus
- https://github.com/argvus/packages
