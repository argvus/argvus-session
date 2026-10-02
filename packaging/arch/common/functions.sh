#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2154
# srcdir, pkgdir, pkgname, and pkgver are supplied by makepkg.

# GitHub source archives use <repository>-v<version> as their top-level
# directory, while the local builder creates <pkgname>-<pkgver>. Normalize
# both forms before check() and package() run.
arch_normalize_source_tree() {
	local expected="${srcdir}/${pkgname}-${pkgver}"
	local -a roots=()

	while IFS= read -r -d '' root; do
		roots+=("$root")
	done < <(find "$srcdir" -mindepth 1 -maxdepth 1 -type d -print0)

	if (( ${#roots[@]} != 1 )); then
		printf 'error: expected exactly one extracted source directory in %s\n' "$srcdir" >&2
		return 1
	fi

	if [[ "${roots[0]}" != "$expected" ]]; then
		[[ ! -e "$expected" ]] || {
			printf 'error: source destination already exists: %s\n' "$expected" >&2
			return 1
		}
		mv -- "${roots[0]}" "$expected"
	fi
}

arch_check_payload() {
	local source_root="${srcdir}/${pkgname}-${pkgver}"

	for executable in argvus-session argvus-sessionctl argvus-start argvus-tty argvus-session-loading; do
		test -x "${source_root}/src/usr/bin/${executable}"
	done
	test -f "${source_root}/src/usr/share/argvus/session/config/wayland-sessions/argvus.desktop"
	test -f "${source_root}/src/usr/share/argvus/session/config/systemd/user/argvus-session.target"
	test -f "${source_root}/src/usr/share/argvus/session/config/systemd/user/argvus-session-reload.service"
	test -f "${source_root}/src/usr/share/argvus/session/config/systemd/user/argvus-config.service"
}

arch_package_payload() {
	local source_root="${srcdir}/${pkgname}-${pkgver}"

	for executable in argvus-session argvus-sessionctl argvus-start argvus-tty argvus-session-loading; do
		install -Dm755 "${source_root}/src/usr/bin/${executable}" \
			"${pkgdir}/usr/bin/${executable}"
	done
	install -dm755 "${pkgdir}/usr/share/argvus/session/sh"
	cp -a "${source_root}/src/usr/share/argvus/session/sh/." \
		"${pkgdir}/usr/share/argvus/session/sh/"
	install -dm755 "${pkgdir}/usr/lib/systemd/user"
	for unit in "${source_root}"/src/usr/share/argvus/session/config/systemd/user/*; do
		install -Dm644 "$unit" "${pkgdir}/usr/lib/systemd/user/${unit##*/}"
	done
	install -Dm644 \
		"${source_root}/src/usr/share/argvus/session/config/wayland-sessions/argvus.desktop" \
		"${pkgdir}/usr/share/wayland-sessions/argvus.desktop"
	install -Dm644 "${source_root}/LICENSE" \
		"${pkgdir}/usr/share/licenses/${pkgname}/LICENSE"
	find "${pkgdir}/usr/bin" "${pkgdir}/usr/share/argvus/session/sh" \
		-type f -exec chmod 755 {} +
}
