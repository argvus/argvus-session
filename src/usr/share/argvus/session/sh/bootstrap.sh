#!/usr/bin/env sh
# shellcheck shell=sh disable=SC1090,SC1091

# =============================================================================
# bootstrap.sh — Carrega automaticamente todos os módulos compartilhados.
#
# Uso em scripts:
#   . "${ARGVUS_SYSTEM_CONFIG:-/usr/share/argvus}/session/sh/bootstrap.sh"
#
# Isso disponibiliza todas as APIs (log_*, string_*, json_*, ...)
# e variáveis globais (WALLPAPER_PATH, BUTTON_LAYOUT, ...).
# =============================================================================

: "${HOME:?HOME is not set}"

ARGVUS_SYSTEM_CONFIG="${ARGVUS_SYSTEM_CONFIG:-/usr/share/argvus}"
ARGVUS_CONFIG_HOME="${ARGVUS_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}"
ARGVUS_DATA_HOME="${ARGVUS_DATA_HOME:-${ARGVUS_CONFIG_HOME}/argvus/data}"
ARGVUS_STATE_HOME="${ARGVUS_STATE_HOME:-${ARGVUS_DATA_HOME}/state}"
ARGVUS_CACHE_HOME="${ARGVUS_CACHE_HOME:-${XDG_CACHE_HOME:-$HOME/.cache}/argvus}"
ARGVUS_BOOTSTRAP="${ARGVUS_BOOTSTRAP:-$ARGVUS_SYSTEM_CONFIG/session/sh/bootstrap.sh}"
ARGVUS_PROJECT_CONFIG_DIRS="$ARGVUS_SYSTEM_CONFIG/portal/config:$ARGVUS_SYSTEM_CONFIG/appearance/config:$ARGVUS_SYSTEM_CONFIG/app-profiles/config:$ARGVUS_SYSTEM_CONFIG/terminal/config:$ARGVUS_SYSTEM_CONFIG/launcher/config:$ARGVUS_SYSTEM_CONFIG/notifications/config:$ARGVUS_SYSTEM_CONFIG/network/config:$ARGVUS_SYSTEM_CONFIG/control-panel/config:$ARGVUS_SYSTEM_CONFIG/taskbar/config:$ARGVUS_SYSTEM_CONFIG"
case ":${XDG_CONFIG_DIRS:-/etc/xdg}:" in
  *":$ARGVUS_SYSTEM_CONFIG/portal/config:"*) ;;
  *) XDG_CONFIG_DIRS="$ARGVUS_PROJECT_CONFIG_DIRS:${XDG_CONFIG_DIRS:-/etc/xdg}" ;;
esac
export XDG_CONFIG_DIRS

BOOTSTRAP_DIR="$(CDPATH='' cd -- "$(dirname -- "$ARGVUS_BOOTSTRAP")" && pwd)"
MODULES_DIR="$BOOTSTRAP_DIR"

for _argvus_module in variables paths locale log string json; do
  . "${MODULES_DIR}/${_argvus_module}.sh"
done

for _argvus_module in notify hypr; do
  if [ -r "${MODULES_DIR}/${_argvus_module}.sh" ]; then
    . "${MODULES_DIR}/${_argvus_module}.sh"
  fi
done

if ! command -v notify_send >/dev/null 2>&1; then
  notify_send() {
    command -v notify-send >/dev/null 2>&1 || return 0
    notify-send "$@" >/dev/null 2>&1 || true
  }
fi

if ! command -v notify_error >/dev/null 2>&1; then
  notify_error() {
    notify_send "$(argvus_tr session error.title): $1" "$2"
  }
fi

if ! command -v hypr_wallpaper_runtime_config >/dev/null 2>&1; then
  hypr_monitors() {
    if command -v hyprctl >/dev/null 2>&1; then
      hyprctl monitors 2>/dev/null |
        sed -n 's/^Monitor \([^ ]*\).*/\1/p'
    fi
  }

  hypr_wallpaper_runtime_config() {
    _wallpaper="$1"
    _runtime_config="$(paths_cache hypr/hyprpaper.conf)"
    mkdir -p "${_runtime_config%/*}"
    {
      _has_monitor=0
      for _monitor in $(hypr_monitors); do
        _has_monitor=1
        printf 'wallpaper {\n'
        printf '  monitor = %s\n' "$_monitor"
        printf '  path = %s\n' "$_wallpaper"
        printf '  fit_mode = cover\n'
        printf '}\n\n'
      done

      if [ "$_has_monitor" -eq 0 ]; then
        printf 'wallpaper {\n'
        printf '  monitor =\n'
        printf '  path = %s\n' "$_wallpaper"
        printf '  fit_mode = cover\n'
        printf '}\n\n'
      fi

      printf 'splash = false\n'
    } > "$_runtime_config"
    printf '%s\n' "$_runtime_config"
  }
fi
