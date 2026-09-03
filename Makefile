PREFIX ?= /usr
DESTDIR ?=
INSTALL ?= install
RM ?= rm -f
SYSTEM_PREFIXES := /usr /usr/local

ifeq ($(origin SUDO), undefined)
SUDO =
ifeq ($(DESTDIR),)
ifneq ($(filter $(PREFIX),$(SYSTEM_PREFIXES)),)
ifneq ($(shell id -u),0)
SUDO = sudo
endif
endif
endif
endif

.DEFAULT_GOAL := help

.PHONY: help install uninstall reload-user-systemd release-archive

help:
	@echo "Available targets:"
	@echo "  make build"
	@echo "  make install"
	@echo "  make uninstall"
	@echo "  make release-archive"

install:
	$(SUDO) $(INSTALL) -Dm755 bin/argvus-session \
		"$(DESTDIR)$(PREFIX)/bin/argvus-session"
	$(SUDO) $(INSTALL) -Dm755 bin/argvus-start \
		"$(DESTDIR)$(PREFIX)/bin/argvus-start"
	$(SUDO) $(INSTALL) -Dm755 bin/argvus-tty \
		"$(DESTDIR)$(PREFIX)/bin/argvus-tty"
	$(SUDO) $(INSTALL) -Dm755 bin/argvus-sessionctl \
		"$(DESTDIR)$(PREFIX)/bin/argvus-sessionctl"
	$(SUDO) $(INSTALL) -dm755 "$(DESTDIR)$(PREFIX)/share/argvus"
	$(SUDO) cp -a usr/share/argvus/. \
		"$(DESTDIR)$(PREFIX)/share/argvus/"
	$(SUDO) find "$(DESTDIR)$(PREFIX)/share/argvus/scripts" -type f -name '*.sh' -exec chmod 755 {} \; 2>/dev/null || true
	$(SUDO) $(INSTALL) -Dm644 usr/share/wayland-sessions/argvus.desktop \
		"$(DESTDIR)$(PREFIX)/share/wayland-sessions/argvus.desktop"
	$(SUDO) $(INSTALL) -Dm644 usr/lib/systemd/user/argvus-session.target \
		"$(DESTDIR)$(PREFIX)/lib/systemd/user/argvus-session.target"
	for unit in usr/lib/systemd/user/argvus-*.service; do \
		$(SUDO) $(INSTALL) -Dm644 "$$unit" \
			"$(DESTDIR)$(PREFIX)/lib/systemd/user/$${unit##*/}"; \
	done
	$(MAKE) reload-user-systemd

uninstall:
	$(SUDO) $(RM) "$(DESTDIR)$(PREFIX)/bin/argvus-session"
	$(SUDO) $(RM) "$(DESTDIR)$(PREFIX)/bin/argvus-start"
	$(SUDO) $(RM) "$(DESTDIR)$(PREFIX)/bin/argvus-tty"
	$(SUDO) $(RM) "$(DESTDIR)$(PREFIX)/bin/argvus-sessionctl"
	$(SUDO) $(RM) "$(DESTDIR)$(PREFIX)/share/argvus/hypr/hyprland.lua"
	$(SUDO) $(RM) "$(DESTDIR)$(PREFIX)/share/argvus/hypr/.luarc.json"
	$(SUDO) $(RM) "$(DESTDIR)$(PREFIX)/share/argvus/hypr/.stylua.toml"
	$(SUDO) $(RM) "$(DESTDIR)$(PREFIX)/share/argvus/scripts/apps/hypr-init.sh"
	for script in bootstrap paths variables locale log string json get-default default_apps_show keyboard-layout-daemon; do \
		$(SUDO) $(RM) "$(DESTDIR)$(PREFIX)/share/argvus/scripts/argvus/$$script.sh"; \
	done
	$(SUDO) $(RM) "$(DESTDIR)$(PREFIX)/share/wayland-sessions/argvus.desktop"
	$(SUDO) $(RM) "$(DESTDIR)$(PREFIX)/lib/systemd/user/argvus-session.target"
	$(SUDO) $(RM) "$(DESTDIR)$(PREFIX)/lib/systemd/user/argvus-*.service"
	$(MAKE) reload-user-systemd

reload-user-systemd:
	@if [ -z "$(DESTDIR)" ] && command -v systemctl >/dev/null 2>&1; then \
		systemctl --user daemon-reload >/dev/null 2>&1 || true; \
	fi

release-archive:
	mkdir -p .release
	git archive --format=tar.gz --prefix="argvus-session-$$(git rev-parse --short HEAD)/" \
		--output=".release/argvus-session-$$(git rev-parse --short HEAD).tar.gz" HEAD

.PHONY: build

build:
	@tools/build-local-package.sh
