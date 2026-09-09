#!/usr/bin/env sh
# Build the Hyprland keyboard cycle from enabled system locales.

set -eu

LOCALE_GEN="${ARGVUS_LOCALE_GEN:-/etc/locale.gen}"

available_layouts() {
  if [ -n "${ARGVUS_XKB_LAYOUTS:-}" ]; then
    printf '%s\n' "$ARGVUS_XKB_LAYOUTS" | tr ' ,:' '\n'
  else
    localectl list-x11-keymap-layouts 2>/dev/null || true
  fi
}

layout_available() {
  printf '%s\n' "$AVAILABLE_LAYOUTS" | grep -Fxq "$1"
}

append_layout() {
  _layout="$1"
  [ -n "$_layout" ] || return 0
  layout_available "$_layout" || return 0
  case ",$LAYOUTS," in
    *",$_layout,"*) return 0 ;;
  esac
  LAYOUTS="${LAYOUTS}${LAYOUTS:+,}${_layout}"
}

append_locale_layout() {
  _locale="${1%%.*}"
  _locale="${_locale%%@*}"
  _language="${_locale%%_*}"
  _region=""
  case "$_locale" in
    *_*) _region="${_locale#*_}" ;;
  esac
  _language="$(printf '%s' "$_language" | tr '[:upper:]' '[:lower:]')"
  _region="$(printf '%s' "$_region" | tr '[:upper:]' '[:lower:]')"

  case "${_language}_${_region}" in
    en_us) append_layout us; return ;;
    en_gb) append_layout gb; return ;;
    pt_br) append_layout br; return ;;
    pt_pt) append_layout pt; return ;;
  esac

  if [ -n "$_region" ] && layout_available "$_region"; then
    append_layout "$_region"
    return
  fi
  append_layout "$_language"
}

AVAILABLE_LAYOUTS="$(available_layouts)"
LAYOUTS=""

if [ -r "$LOCALE_GEN" ]; then
  while IFS= read -r _line || [ -n "$_line" ]; do
    _line="$(printf '%s' "$_line" | sed 's/^[[:space:]]*//')"
    case "$_line" in
      ''|'#'*) continue ;;
    esac
    _locale_entry="${_line%%[[:space:]]*}"
    append_locale_layout "$_locale_entry"
  done < "$LOCALE_GEN"
fi

if [ -z "$LAYOUTS" ]; then
  LAYOUTS="br,us"
fi

case "${1:-cycle}" in
  --list|list)
    printf '%s\n' "$LAYOUTS"
    ;;
  cycle)
    command -v hyprctl >/dev/null 2>&1 || exit 0
    _current="$(hyprctl getoption input:kb_layout -j 2>/dev/null | jq -r '.str // empty' 2>/dev/null || true)"
    if [ "$_current" != "$LAYOUTS" ]; then
      hyprctl keyword input:kb_layout "$LAYOUTS" >/dev/null
    fi
    exec hyprctl switchxkblayout all next
    ;;
  *)
    printf 'Usage: %s [cycle|--list]\n' "$0" >&2
    exit 64
    ;;
esac
