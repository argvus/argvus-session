#!/usr/bin/env sh
# shellcheck shell=sh
#
# get-default.sh <category> — prints the configured default app (binary) for a
# category, falling back to the Argvus built-in default when no state exists.
#
# Reads the single `defaults.json` written by ARGVUS Control Center, with the
# same path precedence used across Argvus:
#   $XDG_CONFIG_HOME/argvus/defaults.json
#       -> /usr/share/argvus/defaults.json
#
# Legacy `$XDG_STATE_HOME/argvus/defaults.json` written by older versions of
# the default-apps tool is still honored while migrating to the argvus/ root.
#
# Categories match the ARGVUS Control Center Apps keys:
#   terminal, file_manager, text_editor, terminal_editor, browser,
#   image_viewer, pdf_viewer, video_player, audio_player, archive, launcher
#
# get-default.sh --all prints `<category><TAB><app>` for every category, each
# app reduced to its first non-empty line, with one jq call for all of them.

set -eu

# shellcheck disable=SC1091
. /usr/share/argvus/lib/i18n.sh

CATEGORY="${1:-}"
CATEGORIES="terminal file_manager text_editor terminal_editor browser image_viewer pdf_viewer video_player audio_player archive launcher"
if [ -z "$CATEGORY" ]; then
  argvus_tr session usage.get_default >&2
  exit 2
fi

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Locate the defaults state file by precedence.
find_state_file() {
  _user="${ARGVUS_CONFIG_HOME:-$XDG_CONFIG_HOME}/argvus/data/control-center/defaults.json"
  _state="$XDG_STATE_HOME/argvus/defaults.json"
  _system="${ARGVUS_SYSTEM_CONFIG:-/usr/share/argvus}/defaults.json"
  if [ -f "$_user" ]; then
    printf '%s\n' "$_user"
  elif [ -f "$_state" ]; then
    printf '%s\n' "$_state"
  elif [ -f "$_system" ]; then
    printf '%s\n' "$_system"
  fi
}

fallback() {
  case "$1" in
    terminal) printf 'argvus-terminal\n' ;;
    file_manager) printf 'argvus --spf\n' ;;
    text_editor) printf 'mousepad\n' ;;
    terminal_editor) printf 'vim\n' ;;
    browser) printf 'xdg-open\n' ;;
    image_viewer) printf 'imv\n' ;;
    pdf_viewer) printf 'zathura\n' ;;
    video_player) printf 'mpv\n' ;;
    audio_player) printf 'audacious\n' ;;
    archive) printf 'xarchiver\n' ;;
    launcher) printf 'rofi\n' ;;
    *) printf '\n' ;;
  esac
}

# The value stored for category $1, or nothing when none is usable.
stored_value() {
  [ -n "$STATE_FILE" ] || return 0
  if command -v jq >/dev/null 2>&1; then
    _val="$(jq -r --arg k "$1" '.[$k] // empty' "$STATE_FILE" 2>/dev/null || true)"
    if [ -n "$_val" ] && [ "$_val" != "null" ]; then
      printf '%s\n' "$_val"
    fi
  else
    # Minimal fallback without jq: grep the first value for "key".
    sed -n "s/^[[:space:]]*\"${1}\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$STATE_FILE" | head -1
  fi
}

# Prints `<category><TAB><app>` for every category. Each app is what
# `get-default.sh <category>` prints, reduced to its first non-empty line, as
# variables.sh reads it. Every `sessionctl run` sources variables.sh and several
# start together at login, so jq runs once here instead of once per category.
print_all() {
  _tab="$(printf '\t')"
  _stored=""
  if [ -n "$STATE_FILE" ] && command -v jq >/dev/null 2>&1; then
    # The same reading as stored_value: `.[$k] // empty`, an exact "null"
    # string is unusable, and only the first non-empty line is kept. `jq -r`
    # prints an object or array over several lines, so its first line is the
    # opening bracket, or the empty value when it has no members.
    _stored="$(jq -r --arg categories "$CATEGORIES" '
      . as $state
      | ($categories | split(" "))[]
      | . as $category
      | ($state[$category] // empty
        | if type == "string" then .
          elif type == "object" then (if length == 0 then "{}" else "{" end)
          elif type == "array" then (if length == 0 then "[]" else "[" end)
          else tojson end
        | select(. != "null")
        | split("\n") | map(select(length > 0)) | first // empty)
      | "\($category)\t\(.)"
    ' "$STATE_FILE" 2>/dev/null || true)"
  elif [ -n "$STATE_FILE" ]; then
    for _category in $CATEGORIES; do
      _value="$(stored_value "$_category")"
      [ -z "$_value" ] || _stored="${_stored}${_category}${_tab}${_value}
"
    done
  fi

  for _category in $CATEGORIES; do
    _app=""
    while IFS="$_tab" read -r _stored_category _stored_app; do
      if [ "$_stored_category" = "$_category" ]; then
        _app="$_stored_app"
        break
      fi
    done <<STORED
$_stored
STORED
    [ -n "$_app" ] || _app="$(fallback "$_category")"
    printf '%s\t%s\n' "$_category" "$_app"
  done
}

STATE_FILE="$(find_state_file)"

if [ "$CATEGORY" = "--all" ]; then
  print_all
  exit 0
fi

val="$(stored_value "$CATEGORY")"
if [ -n "$val" ]; then
  printf '%s\n' "$val"
  exit 0
fi

fallback "$CATEGORY"
