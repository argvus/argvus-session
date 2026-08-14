# Argvus Session

Argvus Session ships the startup infrastructure for the Argvus Desktop
Environment.

It provides:

- `/usr/bin/argvus-session`
- `/usr/bin/argvus-start`
- `/usr/bin/argvus-tty`
- `/usr/share/wayland-sessions/argvus.desktop`

`argvus-session` is the official graphical-session entrypoint. It prepares the
session environment and executes `argvus-start`; it does not copy packaged
configuration into the user's home directory.
`argvus-start` launches Hyprland with the appropriate Argvus configuration and
resets the graphical session identity to Hyprland, so a display-manager greeter
environment is not inherited by the user desktop. `argvus-tty` is the TTY
fallback for starting the same session without a display manager.
By default it uses `$XDG_CONFIG_HOME/hypr/hyprland.lua` when that user override
exists, otherwise it uses `/usr/share/argvus/hypr/hyprland.lua`.

The session prepends `/usr/share/argvus` to `$XDG_CONFIG_DIRS` while preserving
existing directories such as `/etc/xdg`, so applications that support XDG system
configuration can discover packaged Argvus defaults.

The main `argvus` package provides the desktop configuration and
`/usr/bin/argvus-setup`; this package stays as a small reusable session
component.

## Layout

```text
usr/
  share/
    wayland-sessions/
      argvus.desktop
bin/
  argvus-session
  argvus-start
  argvus-tty
```

## Installation

```sh
make install
```

Use `DESTDIR` for packaging:

```sh
make DESTDIR="$pkgdir" PREFIX=/usr install
```

Arch packaging is owned by this repository through `packaging/arch/PKGBUILD`.

## Release Flow

Tag pushes build a signed Arch package and publish it to the shared
`argvus/packages` repository. GitHub Releases are not used for package
distribution.

## Related Repositories

- https://github.com/argvus/argvus
- https://github.com/argvus/packages
