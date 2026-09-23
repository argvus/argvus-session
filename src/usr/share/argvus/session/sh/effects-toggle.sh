#!/usr/bin/env sh

# shellcheck disable=SC1091
ARGVUS_BOOTSTRAP="${ARGVUS_BOOTSTRAP:-${ARGVUS_SYSTEM_CONFIG:-/usr/share/argvus}/session/sh/bootstrap.sh}"
. "$ARGVUS_BOOTSTRAP"
ARGVUS_MUTABLE_CONFIG=1

LEGACY_STATE_FILE="$(paths_state effects)"

state_file() {
  paths_state "$1"
}

detect_vm() {
  if command -v systemd-detect-virt >/dev/null 2>&1; then
    systemd-detect-virt --vm >/dev/null 2>&1
    return $?
  fi

  return 1
}

apply_taskbar_surface() {
  _css="$(paths_config taskbar/config/argvus-taskbar.css 2>/dev/null || true)"
  [ -f "$_css" ] || return 0
  if ! grep -q '^@define-color th-background-effective ' "$_css"; then
    sed -i '/^@define-color transparent transparent;$/a @define-color th-background-effective @th-background-rgba;' "$_css"
    sed -i 's/background: @th-background-rgba;/background: @th-background-effective;/' "$_css"
  fi
  if ! grep -q '^@define-color th-mpris-bg-effective ' "$_css"; then
    sed -i '/^@define-color th-background-effective /a @define-color th-mpris-bg-effective @th-mpris-bg;' "$_css"
    sed -i 's/background: @th-mpris-bg;/background: @th-mpris-bg-effective;/' "$_css"
  fi
  if [ "$1" = "disabled" ]; then
    sed -i 's/^@define-color th-background-effective .*/@define-color th-background-effective @th-background;/' "$_css"
    sed -i 's/^@define-color th-mpris-bg-effective .*/@define-color th-mpris-bg-effective @th-right1-bg;/' "$_css"
  else
    sed -i 's/^@define-color th-background-effective .*/@define-color th-background-effective @th-background-rgba;/' "$_css"
    sed -i 's/^@define-color th-mpris-bg-effective .*/@define-color th-mpris-bg-effective @th-mpris-bg;/' "$_css"
  fi

  if [ "${2:-enabled}" = "disabled" ]; then
    if ! grep -q '^/\* ARGVUS animations disabled \*/$' "$_css"; then
      printf '%s\n' \
        '/* ARGVUS animations disabled */' \
        '#workspaces button, #right-2, #custom-expand-icon {' \
        '  transition: none;' \
        '}' \
        '#mpris, #custom-spotify-mpris, #custom-recording.recording {' \
        '  animation: none;' \
        '}' \
        '/* ARGVUS animations disabled end */' >> "$_css"
    fi
  else
    sed -i '/^\/\* ARGVUS animations disabled \*\//,/^\/\* ARGVUS animations disabled end \*\//d' "$_css"
  fi
}

theme_background() {
  case "$(sed -n '1p' "${ARGVUS_CONFIG_HOME}/argvus/.active-theme" 2>/dev/null || true)" in
    argvus-dracula|argvus-dracula-float) printf '#282A36\n' ;;
    argvus-dark-slate|argvus-dark-slate-float) printf '#2f3541\n' ;;
    argvus-light-veil|argvus-light-veil-float) printf '#f7f7f7\n' ;;
    argvus-frost|argvus-frost-float) printf '#f6f8fa\n' ;;
    argvus-catppuccin-latte|argvus-catppuccin-latte-float) printf '#EFF1F5\n' ;;
    argvus-dark-universe|argvus-dark-universe-float) printf '#000000\n' ;;
    argvus-gruvbox-dark-medium|argvus-gruvbox-dark-medium-float) printf '#282828\n' ;;
    argvus-onedark|argvus-onedark-float) printf '#282C34\n' ;;
    *) printf '#111316\n' ;;
  esac
}

apply_widget_telemetry_surface() {
  _css="$(paths_config widget-telemetry/config/argvus-widget-telemetry.css 2>/dev/null || true)"
  [ -f "$_css" ] || return 0
  if ! grep -q '^@define-color th-window-bg-effective ' "$_css"; then
    sed -i '/^\/\*  Waybar — Painel vertical/a @define-color th-window-bg-effective @th-window-bg;' "$_css"
    sed -i 's/background: @th-window-bg;/background: @th-window-bg-effective;/' "$_css"
  fi
  if [ "$1" = "disabled" ]; then
    sed -i 's/^@define-color th-window-bg-effective .*/@define-color th-window-bg-effective @th-background;/' "$_css"
  else
    sed -i 's/^@define-color th-window-bg-effective .*/@define-color th-window-bg-effective @th-window-bg;/' "$_css"
  fi
}

apply_launcher_surface() {
  _theme="$(paths_config launcher/config/theme.rasi 2>/dev/null || true)"
  [ -f "$_theme" ] || return 0
  if [ "$1" = "disabled" ]; then
    _background="$(theme_background)"
  else
    _background='@th-bg'
  fi
  sed -i "s|^[[:space:]]*bg:[[:space:]].*;|    bg:               ${_background};|" "$_theme"
}

apply_dunst_surface() {
  _dunstrc="$(paths_config notifications/config/dunstrc 2>/dev/null || true)"
  _backup="$(paths_state effects-dunst-transparency)"
  [ -f "$_dunstrc" ] || return 0
  if [ "$1" = "disabled" ]; then
    if [ ! -f "$_backup" ]; then
      _current="$(sed -n 's/^[[:space:]]*transparency[[:space:]]*=[[:space:]]*\([0-9][0-9]*\).*/\1/p' "$_dunstrc" | head -n1)"
      case "$_current" in ''|*[!0-9]*) _current=10 ;; esac
      mkdir -p "${_backup%/*}"
      printf '%s\n' "$_current" > "$_backup"
    fi
    sed -i 's/^[[:space:]]*transparency[[:space:]]*=.*/    transparency = 0/' "$_dunstrc"
  else
    _current="$(sed -n '1p' "$_backup" 2>/dev/null || true)"
    case "$_current" in ''|*[!0-9]*) _current=10 ;; esac
    sed -i "s/^[[:space:]]*transparency[[:space:]]*=.*/    transparency = ${_current}/" "$_dunstrc"
    rm -f "$_backup"
  fi
}

apply_calendar_surface() {
  _css="${XDG_CACHE_HOME:-$HOME/.cache}/argvus-taskbar-calendar/theme.css"
  [ -f "$_css" ] || return 0
  if ! grep -q '^@define-color argvus_bg_effective ' "$_css"; then
    sed -i '/^@define-color argvus_bg_alpha /a @define-color argvus_bg_effective @argvus_bg_alpha;' "$_css"
    sed -i 's/background: @argvus_bg_alpha;/background: @argvus_bg_effective;/' "$_css"
  fi
  if [ "$1" = "disabled" ]; then
    sed -i 's/^@define-color argvus_bg_effective .*/@define-color argvus_bg_effective @argvus_bg;/' "$_css"
  else
    sed -i 's/^@define-color argvus_bg_effective .*/@define-color argvus_bg_effective @argvus_bg_alpha;/' "$_css"
  fi
}

apply_foot_surface() {
  _theme="$(sed -n '1p' "${ARGVUS_CONFIG_HOME}/argvus/.active-theme" 2>/dev/null || true)"
  [ -n "$_theme" ] || _theme='argvus-dark-aether'
  _foot_config="$(paths_config app-profiles/config/foot/foot.ini 2>/dev/null || true)"
  _theme_file="${_foot_config%/*}/themes/${_theme}/theme.ini"
  [ -f "$_theme_file" ] || return 0
  _backup="$(paths_state "effects-foot-background-${_theme}")"

  if [ "$1" = "disabled" ]; then
    _background="$(sed -n 's/^[[:space:]]*background[[:space:]]*=[[:space:]]*\([^[:space:]#;]*\).*/\1/p' "$_theme_file" | head -n1)"
    _hex="${_background#\#}"
    case "$_hex" in
      ???????? )
        if [ ! -f "$_backup" ]; then
          mkdir -p "${_backup%/*}"
          printf '%s\n' "$_background" > "$_backup"
        fi
        sed -i "s/^[[:space:]]*background[[:space:]]*=.*/background = ${_hex%??}/" "$_theme_file"
        ;;
    esac
  elif [ -f "$_backup" ]; then
    _background="$(sed -n '1p' "$_backup")"
    [ -n "$_background" ] && sed -i "s/^[[:space:]]*background[[:space:]]*=.*/background = ${_background}/" "$_theme_file"
    rm -f "$_backup"
  fi
}

apply_superfile_surface() {
  _config="$(paths_config app-profiles/config/superfile/config.toml 2>/dev/null || true)"
  [ -f "$_config" ] || return 0
  if [ "$1" = "disabled" ]; then
    _transparent=false
  else
    _transparent=true
  fi
  if grep -q '^[[:space:]]*transparent_background[[:space:]]*=' "$_config"; then
    sed -i "s/^[[:space:]]*transparent_background[[:space:]]*=.*/transparent_background = ${_transparent}/" "$_config"
  else
    printf '\ntransparent_background = %s\n' "$_transparent" >> "$_config"
  fi
}

apply_hyprlock_effects() {
  _script="$(paths_config lock/sh/hyprlock-theme.sh 2>/dev/null || true)"
  [ -f "$_script" ] && sh "$_script" >/dev/null 2>&1 || true
}

apply_surfaces() {
  _transparency_status="$1"
  _animations_status="${2:-enabled}"
  apply_taskbar_surface "$_transparency_status" "$_animations_status"
  apply_widget_telemetry_surface "$_transparency_status"
  apply_launcher_surface "$_transparency_status"
  apply_dunst_surface "$_transparency_status"
  apply_calendar_surface "$_transparency_status"
  apply_foot_surface "$_transparency_status"
  apply_superfile_surface "$_transparency_status"
  apply_hyprlock_effects
}

default_status() {
  if [ "${ARGVUS_LOW_POWER:-0}" = "1" ] || detect_vm; then
    printf 'disabled\n'
  else
    printf 'enabled\n'
  fi
}

legacy_status() {
  case "$(sed -n '1p' "$LEGACY_STATE_FILE" 2>/dev/null || true)" in
    enabled|disabled) sed -n '1p' "$LEGACY_STATE_FILE" ;;
    *) default_status ;;
  esac
}

status() {
  _component="$1"
  _state_file="$(state_file "$_component")"
  case "$(sed -n '1p' "$_state_file" 2>/dev/null || true)" in
    enabled|disabled) sed -n '1p' "$_state_file" ;;
    *) legacy_status ;;
  esac
}

apply_runtime() {
  if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
  fi

  if command -v argvus-sessionctl >/dev/null 2>&1; then
    argvus-sessionctl restart waybar >/dev/null 2>&1 || true
    argvus-sessionctl restart dunst >/dev/null 2>&1 || true
    argvus-sessionctl restart control-panel >/dev/null 2>&1 || true
  fi

  command -v argvus-taskbar-calendar >/dev/null 2>&1 && argvus-taskbar-calendar reload >/dev/null 2>&1 || true

  # Kitty keeps its own background alpha in the generated config. Rebuild it
  # after changing the shared effects state and ask running instances to reload.
  if command -v argvus-terminal >/dev/null 2>&1; then
    argvus-terminal --apply "$(sed -n '1p' "${ARGVUS_CONFIG_HOME}/argvus/.active-theme" 2>/dev/null || true)" >/dev/null 2>&1 || true
    for _pid in $(pgrep -x kitty 2>/dev/null); do
      kill -USR1 "$_pid" 2>/dev/null || true
    done
  fi

  # Foot reads its background alpha only when a new terminal starts. SIGUSR1
  # asks existing instances to reload the generated active theme.
  for _pid in $(pgrep -x foot 2>/dev/null) $(pgrep -x footclient 2>/dev/null); do
    kill -USR1 "$_pid" 2>/dev/null || true
  done
}

set_status() {
  _component="$1"
  _status="$2"
  _state_file="$(state_file "$_component")"
  mkdir -p "${_state_file%/*}"
  printf '%s\n' "$_status" > "$_state_file"
  apply_surfaces "$(status transparency)" "$(status animations)"
  printf '%s\n' "$_status"
  apply_runtime >/dev/null 2>&1 &
}

set_legacy_status() {
  _status="$1"
  mkdir -p "${LEGACY_STATE_FILE%/*}"
  printf '%s\n' "$_status" > "$(state_file animations)"
  printf '%s\n' "$_status" > "$(state_file transparency)"
  apply_surfaces "$_status" "$_status"
  printf '%s\n' "$_status"
  apply_runtime >/dev/null 2>&1 &
}

toggle_component() {
  _component="$1"
  case "$(status "$_component")" in
    enabled) set_status "$_component" disabled ;;
    *) set_status "$_component" enabled ;;
  esac
}

component_command() {
  _component="$1"
  case "${2:-status}" in
    status)
      status "$_component"
      ;;
    enable|on|enabled)
      set_status "$_component" enabled
      ;;
    disable|off|disabled)
      set_status "$_component" disabled
      ;;
    toggle)
      toggle_component "$_component"
      ;;
    *)
      argvus_tr session usage.effects "command=${0##*/}" >&2
      exit 64
      ;;
  esac
}

case "${1:-status}" in
  animations|transparency)
    component_command "$1" "${2:-status}"
    ;;
  status)
    # Legacy aggregate status: enabled only when both independent settings are
    # enabled. New callers should request a component explicitly.
    if [ "$(status animations)" = enabled ] && [ "$(status transparency)" = enabled ]; then
      printf 'enabled\n'
    else
      printf 'disabled\n'
    fi
    ;;
  enable|on|enabled)
    set_legacy_status enabled
    ;;
  disable|off|disabled)
    set_legacy_status disabled
    ;;
  toggle)
    # Keep the legacy shortcut semantic focused on animations. Explicit old
    # enable/disable commands above still update both settings.
    toggle_component animations
    ;;
  apply)
    # theme-switch invokes this while argvus-session-prepare is still a
    # required dependency of Waybar, Quickshell, and the other desktop units.
    # Restarting any of them here creates a systemd job cycle: preparation
    # waits for the restart while those services wait for preparation.
    apply_surfaces "$(status transparency)" "$(status animations)"
    ;;
  *)
    argvus_tr session usage.effects "command=${0##*/}" >&2
    exit 64
    ;;
esac
