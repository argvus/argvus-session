# shellcheck shell=sh disable=SC2034

# -- Environment root ----------------------------------------------------------
ARGVUS_SYSTEM_CONFIG="${ARGVUS_SYSTEM_CONFIG:-/usr/share/argvus}"
ARGVUS_CONFIG_HOME="${ARGVUS_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}"
ARGVUS_DATA_HOME="${ARGVUS_DATA_HOME:-${ARGVUS_CONFIG_HOME}/argvus/data}"
ARGVUS_STATE_HOME="${ARGVUS_STATE_HOME:-${ARGVUS_DATA_HOME}/state}"
ARGVUS_CACHE_HOME="${ARGVUS_CACHE_HOME:-${XDG_CACHE_HOME:-$HOME/.cache}/argvus}"
# Private ARGVUS executables. Session and login scripts use these absolute
# paths because they can run before the user PATH is established.
ARGVUS_COMMANDS_DIR="${ARGVUS_COMMANDS_DIR:-/usr/lib/argvus/commands}"
ENVIRONMENT_ROOT="${ENVIRONMENT_ROOT:-$ARGVUS_SYSTEM_CONFIG/session/sh}"

# -- Cache directories --------------------------------------------------------
HYPR_CACHE_DIR="${ARGVUS_CACHE_HOME}/hypr"
WAYBAR_CACHE_DIR="${ARGVUS_CACHE_HOME}/waybar"

# -- Set variables global ------------------------------------------------------
# Button Layout restored usage: appmenu:minimize,maximize,close
BUTTON_LAYOUT=":"
GTK_THEME="Adwaita-dark"
GTK_CURSOR="Adwaita"

# -- Application defaults -----------------------------------------------------
# $BOOTSTRAP_DIR is set by bootstrap.sh before sourcing this file. When not
# present (standalone use), fall back to the packaged location on PATH or
# /usr/share/argvus so TERM/FINDER still resolve.
_GET_DEFAULT="${BOOTSTRAP_DIR:-${ARGVUS_SYSTEM_CONFIG:-/usr/share/argvus}/session/sh}/get-default.sh"
get_default_value() {
  _cat="$1"
  if [ -x "$_GET_DEFAULT" ]; then
    sh "$_GET_DEFAULT" "$_cat"
  elif command -v get-default >/dev/null 2>&1; then
    get-default "$_cat"
  else
    # Local fallback matching ARGVUS Control Center Apps defaults.
    case "$_cat" in
      terminal) printf 'argvus-terminal\n' ;;
      file_manager) printf 'argvus --spf\n' ;;
      terminal_editor) printf 'vim\n' ;;
      text_editor) printf 'mousepad\n' ;;
      image_viewer) printf 'imv\n' ;;
      pdf_viewer) printf 'zathura\n' ;;
      video_player) printf 'mpv\n' ;;
      audio_player) printf 'audacious\n' ;;
      archive) printf 'xarchiver\n' ;;
      launcher) printf 'rofi\n' ;;
      browser) printf 'xdg-open\n' ;;
      *) printf '\n' ;;
    esac
  fi
}

# -- Application paths --------------------------------------------------------
# Stores the default app of one category in its variable.
_argvus_assign_app_default() {
  case "$1" in
    terminal) TERM="$2" ;;
    launcher) FINDER="$2" ;;
    file_manager) FILE_MANAGER="$2" ;;
    terminal_editor) TERMINAL_EDITOR="$2" ;;
    text_editor) TEXT_EDITOR="$2" ;;
    image_viewer) IMAGE_VIEWER="$2" ;;
    pdf_viewer) PDF_VIEWER="$2" ;;
    video_player) VIDEO_PLAYER="$2" ;;
    audio_player) AUDIO_PLAYER="$2" ;;
    archive) ARCHIVE_APP="$2" ;;
  esac
}

TERM="" FINDER="" FILE_MANAGER="" TERMINAL_EDITOR="" TEXT_EDITOR=""
IMAGE_VIEWER="" PDF_VIEWER="" VIDEO_PLAYER="" AUDIO_PLAYER="" ARCHIVE_APP=""
if [ -x "$_GET_DEFAULT" ]; then
  # One get-default.sh run for every category: each `sessionctl run` sources
  # this module, and several start together at login.
  _argvus_tab="$(printf '\t')"
  while IFS="$_argvus_tab" read -r _argvus_category _argvus_app; do
    _argvus_assign_app_default "$_argvus_category" "$_argvus_app"
  done <<APP_DEFAULTS
$(sh "$_GET_DEFAULT" --all 2>/dev/null || true)
APP_DEFAULTS
else
  for _argvus_category in terminal launcher file_manager terminal_editor text_editor \
    image_viewer pdf_viewer video_player audio_player archive; do
    _argvus_assign_app_default "$_argvus_category" \
      "$(get_default_value "$_argvus_category" | sed '/^$/d' | head -1)"
  done
fi
[ -n "$TERM" ] || TERM="argvus-terminal"
[ -n "$FINDER" ] || FINDER="rofi"
[ -n "$FILE_MANAGER" ] || FILE_MANAGER="argvus --spf"
[ -n "$TERMINAL_EDITOR" ] || TERMINAL_EDITOR="vim"
[ -n "$TEXT_EDITOR" ] || TEXT_EDITOR="mousepad"
[ -n "$IMAGE_VIEWER" ] || IMAGE_VIEWER="imv"
[ -n "$PDF_VIEWER" ] || PDF_VIEWER="zathura"
[ -n "$VIDEO_PLAYER" ] || VIDEO_PLAYER="mpv"
[ -n "$AUDIO_PLAYER" ] || AUDIO_PLAYER="audacious"
[ -n "$ARCHIVE_APP" ] || ARCHIVE_APP="xarchiver"

# -- UI defaults --------------------------------------------------------------
BAR_SIZE="8"

# -- Active theme -------------------------------------------------------------
ACTIVE_THEME="argvus-dark"
