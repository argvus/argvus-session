PREFIX ?= /usr
DESTDIR ?=

.DEFAULT_GOAL := help

.PHONY: help install uninstall release-archive

help:
	@echo "Available targets:"
	@echo "  make install"
	@echo "  make uninstall"
	@echo "  make release-archive"

install:
	install -Dm755 bin/argvus-session \
		"$(DESTDIR)$(PREFIX)/bin/argvus-session"
	install -Dm755 bin/argvus-start \
		"$(DESTDIR)$(PREFIX)/bin/argvus-start"
	install -Dm755 bin/argvus-tty \
		"$(DESTDIR)$(PREFIX)/bin/argvus-tty"
	install -Dm644 usr/share/wayland-sessions/argvus.desktop \
		"$(DESTDIR)$(PREFIX)/share/wayland-sessions/argvus.desktop"

uninstall:
	rm -f "$(DESTDIR)$(PREFIX)/bin/argvus-session"
	rm -f "$(DESTDIR)$(PREFIX)/bin/argvus-start"
	rm -f "$(DESTDIR)$(PREFIX)/bin/argvus-tty"
	rm -f "$(DESTDIR)$(PREFIX)/share/wayland-sessions/argvus.desktop"

release-archive:
	mkdir -p .release
	git archive --format=tar.gz --prefix="argvus-session-$$(git rev-parse --short HEAD)/" \
		--output=".release/argvus-session-$$(git rev-parse --short HEAD).tar.gz" HEAD
