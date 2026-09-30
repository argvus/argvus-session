#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/../.." && pwd)"

die() {
	printf 'error: %s\n' "$1" >&2
	exit 1
}

require_command() {
	command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

require_command bash
require_command makepkg
require_command shellcheck

cd "$ROOT_DIR"

shellcheck tools/sh/*.sh packaging/arch/common/*.sh src/usr/bin/*
bash -n tools/sh/*.sh packaging/arch/common/*.sh src/usr/bin/*

metadata() {
	bash -c '
		source "$1"
		printf "%s\n" "$pkgname" "$pkgver" "$pkgrel" "$pkgdesc"
		printf "%s\n" "${arch[*]}" "${license[*]}" "${depends[*]}"
		printf "%s\n" "${makedepends[*]}" "${options[*]}"
	' bash "$1"
}

ci_metadata="$(metadata packaging/arch/ci/PKGBUILD)"
local_metadata="$(metadata packaging/arch/local/PKGBUILD)"
[[ "$ci_metadata" == "$local_metadata" ]] || die \
	"CI and local PKGBUILD metadata is out of sync"

for pkgbuild_dir in packaging/arch/ci packaging/arch/local; do
	pkgbuild="$pkgbuild_dir/PKGBUILD"
	[[ -f "$pkgbuild" ]] || die "missing $pkgbuild"
	(
		cd "$pkgbuild_dir"
		makepkg -p PKGBUILD --printsrcinfo >/dev/null
	)
done

for executable in argvus-session argvus-sessionctl argvus-start argvus-tty; do
	[[ -x "src/usr/bin/$executable" ]] || die "missing executable src/usr/bin/$executable"
done
[[ -f src/usr/share/argvus/session/config/wayland-sessions/argvus.desktop ]] || die "missing Wayland session desktop entry"
[[ -f src/usr/share/argvus/session/config/systemd/user/argvus-session.target ]] || die "missing session target"
[[ -f src/usr/share/argvus/session/config/systemd/user/argvus-session-reload.service ]] || die "missing session reload service"

git diff --check
printf 'Validation OK\n'
