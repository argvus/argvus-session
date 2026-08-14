# Development

Argvus Session ships the startup scripts and Wayland session entry used by the
Argvus desktop.

## Requirements

This repository is shell-script and desktop-entry based. Local validation
requires `make` and POSIX shell tooling.

On Arch Linux, the package recipe lives at `packaging/arch/PKGBUILD`.

## Commands

Validate the expected files:

```sh
test -f usr/share/wayland-sessions/argvus.desktop
test ! -e usr/share/xsessions/argvus.desktop
grep -q '^Exec=argvus-session$' usr/share/wayland-sessions/argvus.desktop
grep -q '^TryExec=argvus-session$' usr/share/wayland-sessions/argvus.desktop
test -x bin/argvus-session
test -x bin/argvus-start
test -x bin/argvus-tty
sh -n bin/argvus-session bin/argvus-start bin/argvus-tty
```

Validate installation into a staging directory:

```sh
make DESTDIR=/tmp/argvus-session-pkg PREFIX=/usr install
```

## Package Contents

The Arch package installs:

```text
/usr/bin/argvus-session
/usr/bin/argvus-start
/usr/bin/argvus-tty
/usr/share/wayland-sessions/argvus.desktop
/usr/share/licenses/argvus-session/LICENSE
```

The package is architecture-independent, so `makepkg` produces a file named
`argvus-session-X.Y.Z-1-any.pkg.tar.zst`. It is still published under
`argvus/packages/public/arch/x86_64/`, matching the repository layout used by
the Argvus package server.

## Release Flow

1. Tag `vX.Y.Z` and push the tag.
2. Confirm the package workflow builds `argvus-session-X.Y.Z-1-any.pkg.tar.zst` and its `.sig`.
3. Confirm the workflow publishes both files to `argvus/packages` under `public/arch/x86_64/` and updates the Arch repository database.

The project does not create GitHub Releases for package distribution. The built
`.pkg.tar.zst` and `.sig` are kept as GitHub Actions artifacts for one day only;
the permanent package copies live in `argvus/packages`.
