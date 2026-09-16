# Development

Argvus Session ships the startup scripts and Wayland session entry used by the
Argvus desktop.

## Repository layout

The repository follows the ARGVUS packaging-only skeleton:

```text
packaging/arch/
  ci/PKGBUILD       # tagged release source
  local/PKGBUILD    # local archive source
  common/            # shared source normalization and payload functions
src/usr/             # installed package payload
tools/sh/            # validation and local build scripts
```

## Requirements

This repository is shell-script and desktop-entry based. Local validation
requires `make` and POSIX shell tooling.

On Arch Linux, the package recipe lives at `packaging/arch/PKGBUILD`.

## Commands

Validate the expected files:

```sh
test -f src/usr/share/argvus/session/config/wayland-sessions/argvus.desktop
grep -q '^Exec=argvus-session$' src/usr/share/argvus/session/config/wayland-sessions/argvus.desktop
grep -q '^TryExec=argvus-session$' src/usr/share/argvus/session/config/wayland-sessions/argvus.desktop
test -x src/usr/bin/argvus-session
test -x src/usr/bin/argvus-start
test -x src/usr/bin/argvus-tty
sh -n src/usr/bin/argvus-session src/usr/bin/argvus-start src/usr/bin/argvus-tty
```

Validate installation into a staging directory:

```sh
make build
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
