#!/usr/bin/env sh
# Build the Hyprland keyboard cycle.
#
# The list comes from the Control Center generated config first (generated/hypr/input.lua),
# falling back to the enabled system locales when no generated config exists.

set -eu

LOCALE_GEN="${ARGVUS_LOCALE_GEN:-/etc/locale.gen}"
HOMEDIR="${HOME:-/tmp}"

CONFIG_HOME="${ARGVUS_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOMEDIR/.config}}"
GENERATED_INPUT="${CONFIG_HOME}/argvus/generated/hypr/input.lua"

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
  case "$_layout" in
    *[!A-Za-z0-9_-]*) return 0 ;;
  esac
  layout_available "$_layout" || return 0
  case ",$LAYOUTS," in
    *",$_layout,"*) return 0 ;;
  esac
  LAYOUTS="${LAYOUTS}${LAYOUTS:+,}${_layout}"
}

seed_from_generated_input() {
  [ -r "$GENERATED_INPUT" ] || return 0
  _value="$(sed -n 's/^[[:space:]]*kb_layout[[:space:]]*=[[:space:]]*"\([^"]*\)",*[[:space:]]*$/ \1/p' "$GENERATED_INPUT" | head -n1 2>/dev/null || true)"
  case "$_value" in
    ''|*[!A-Za-z0-9_,-]*) return 0 ;;
  esac
  for _layout in $(printf '%s' "$_value" | tr ',' ' '); do
    append_layout "$_layout"
  done
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

# Keep a manually selected layout usable when no matching locale is enabled.
# Enabled locale entries remain the source of truth for the taskbar choices.
if [ -z "$LAYOUTS" ]; then
  seed_from_generated_input
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
