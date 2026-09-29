#!/usr/bin/env sh

# shellcheck disable=SC1091
ARGVUS_BOOTSTRAP="${ARGVUS_BOOTSTRAP:-${ARGVUS_SYSTEM_CONFIG:-/usr/share/argvus}/session/sh/bootstrap.sh}"
. "$ARGVUS_BOOTSTRAP"
ARGVUS_MUTABLE_CONFIG=1

LEGACY_STATE_FILE="$(paths_state effects)"

active_theme() {
  _theme="$(sed -n '1p' "${ARGVUS_CONFIG_HOME}/argvus/.active-theme" 2>/dev/null || true)"
  [ -n "$_theme" ] || _theme=argvus-dark
  printf '%s\n' "$_theme"
}

theme_effects_file() {
  printf '%s/effects/%s.conf\n' "$(paths_state)" "$(active_theme)"
}

ensure_theme_effects() {
  _file="$(theme_effects_file)"
  mkdir -p "${_file%/*}"
  [ -f "$_file" ] || : > "$_file"
  if grep -q '^launcher\.' "$_file"; then
    sed -i 's/^launcher\./launchers./' "$_file"
  fi
  for _entry in \
    'taskbar.transparency=50' \
    'control-panel.transparency=50' \
    'widget-telemetry.transparency=50' \
    'taskbar.transparency.enabled=enabled' \
    'control-panel.transparency.enabled=enabled' \
    'widget-telemetry.transparency.enabled=enabled' \
    'taskbar.blur=50' \
    'control-panel.blur=50' \
    'widget-telemetry.blur=50' \
    'taskbar.blur.enabled=enabled' \
    'control-panel.blur.enabled=enabled' \
    'widget-telemetry.blur.enabled=enabled' \
    'terminal.transparency=50' \
    'terminal.transparency.enabled=enabled' \
    'launchers.transparency=50' \
    'launchers.transparency.enabled=enabled'; do
    _entry_key="${_entry%%=*}"
    grep -q "^${_entry_key}=" "$_file" || printf '%s\n' "$_entry" >> "$_file"
  done
}

global_effect_value() {
  _key="$1"
  if command -v argvus-config >/dev/null 2>&1; then
    _value="$(argvus-config get "/effects/${_key}" --effective --raw 2>/dev/null || true)"
    case "$_value" in
      ''|*[!0-9]*) ;;
      *) [ "$_value" -le 100 ] && { printf '%s\n' "$_value"; return 0; } ;;
    esac
  fi
  printf '50\n'
}

global_effect_enabled() {
  if command -v argvus-config >/dev/null 2>&1; then
    _value="$(argvus-config get /effects/blur_global_enabled --effective --raw 2>/dev/null || true)"
    case "$_value" in
      true|enabled) printf 'enabled\n'; return 0 ;;
      false|disabled) printf 'disabled\n'; return 0 ;;
    esac
  fi
  legacy_status
}

# Canonical config.json effect pointers per surface. The transparency value and
# every per-surface enabled flag are owned by config.json (the single source of
# truth); per-surface blur values have no config.json key and stay inside the
# per-theme effects projection file.
config_value_key() {
  case "$1" in
    taskbar) printf '/effects/transparency_taskbar_value' ;;
    control-panel) printf '/effects/transparency_control-panel_value' ;;
    widget-telemetry) printf '/effects/transparency_widget-telemetry_value' ;;
    terminal) printf '/effects/transparency_terminal_value' ;;
    launchers) printf '/effects/transparency_launchers_value' ;;
    *) return 1 ;;
  esac
}

config_enabled_key() {
  case "$1:$2" in
    taskbar:transparency) printf '/effects/transparency_taskbar_enabled' ;;
    control-panel:transparency) printf '/effects/transparency_control-panel_enabled' ;;
    widget-telemetry:transparency) printf '/effects/transparency_widget-telemetry_enabled' ;;
    terminal:transparency) printf '/effects/transparency_terminal_enabled' ;;
    launchers:transparency) printf '/effects/transparency_launchers_enabled' ;;
    taskbar:blur) printf '/effects/blur_taskbar_enabled' ;;
    control-panel:blur) printf '/effects/blur_control-panel_enabled' ;;
    widget-telemetry:blur) printf '/effects/blur_widget-telemetry_enabled' ;;
    terminal:blur) printf '/effects/blur_terminal_enabled' ;;
    launchers:blur) printf '/effects/blur_launchers_enabled' ;;
    *) return 1 ;;
  esac
}

# Reads a raw effective value straight from config.json. Returns a failure when
# the tool is unavailable so callers can fall back to the effects projection.
config_get_raw() {
  command -v argvus-config >/dev/null 2>&1 || return 1
  _value="$(argvus-config get "$1" --effective --raw 2>/dev/null || true)"
  [ -n "$_value" ] || return 1
  printf '%s\n' "$_value"
}

effect_value() {
  _key="$1"
  ensure_theme_effects
  _surface="${_key%%.*}"
  _kind="${_key#*.}"
  if [ "$_kind" = transparency ] && _pointer="$(config_value_key "$_surface")"; then
    _value="$(config_get_raw "$_pointer")"
    case "$_value" in
      ''|*[!0-9]*) ;;
      *) [ "$_value" -le 100 ] && { printf '%s\n' "$_value"; return 0; } ;;
    esac
  fi
  _value="$(sed -n "s/^${_key}=//p" "$(theme_effects_file)" | head -n1)"
  case "$_value" in
    ''|*[!0-9]*) _value=0 ;;
  esac
  [ "$_value" -le 100 ] || _value=100
  printf '%s\n' "$_value"
}

effect_enabled() {
  _key="$1.enabled"
  ensure_theme_effects
  _surface="${1%%.*}"
  _kind="${1#*.}"
  if _pointer="$(config_enabled_key "$_surface" "$_kind")" && _value="$(config_get_raw "$_pointer")"; then
    case "$_value" in
      true|enabled) printf 'enabled\n'; return 0 ;;
      false|disabled) printf 'disabled\n'; return 0 ;;
    esac
  fi
  _value="$(sed -n "s/^${_key}=//p" "$(theme_effects_file)" | head -n1)"
  case "$_value" in
    enabled|disabled) printf '%s\n' "$_value" ;;
    *)
      case "$1" in
        taskbar.transparency|control-panel.transparency|widget-telemetry.transparency|\
        taskbar.blur|control-panel.blur|widget-telemetry.blur) printf 'enabled\n' ;;
        *) status "${1#*.}" ;;
      esac
      ;;
  esac
}

# Persists a config.json effect value when the surface owns one. Failures are
# tolerated so the per-theme projection still works while argvus-config is
# temporarily unavailable.
config_set_value() {
  _pointer="$1"
  _value="$2"
  command -v argvus-config >/dev/null 2>&1 || return 0
  argvus-config set "$_pointer" "$_value" >/dev/null 2>&1 || true
}

config_set_flag() {
  _pointer="$1"
  _status="$2"
  command -v argvus-config >/dev/null 2>&1 || return 0
  argvus-config set "$_pointer" "$([ "$_status" = enabled ] && printf true || printf false)" >/dev/null 2>&1 || true
}

request_config_reload() {
  [ "${ARGVUS_CONFIG_SERVICE:-0}" = 1 ] && return 0
  [ "${ARGVUS_PROJECTING:-0}" = 1 ] && return 0
  command -v systemctl >/dev/null 2>&1 || return 0
  systemctl --user reload argvus-config.service
}

set_effect_value() {
  _key="$1"
  _value="$2"
  case "$_value" in
    ''|*[!0-9]*) return 64 ;;
  esac
  [ "$_value" -le 100 ] || return 64
  ensure_theme_effects
  _file="$(theme_effects_file)"
  _tmp="${_file}.tmp.$$"
  awk -F= -v key="$_key" -v value="$_value" '
    BEGIN { updated = 0 }
    $1 == key { print key "=" value; updated = 1; next }
    { print }
    END { if (!updated) print key "=" value }
  ' "$_file" > "$_tmp" && mv -f "$_tmp" "$_file"
  _surface="${_key%%.*}"
  _kind="${_key#*.}"
  if [ "$_kind" = transparency ] && _pointer="$(config_value_key "$_surface")"; then
    config_set_value "$_pointer" "$_value"
  fi
}

opacity_factor() {
  # A transparency value is a percentage of transparency: 0 is opaque and
  # 100 is fully transparent. Waybar's alpha value is the inverse quantity.
  awk -v transparency="$1" 'BEGIN { printf "%.2f\n", 1 - (transparency / 100) }'
}

ensure_waybar_namespace() {
  _config="$1"
  _namespace="$2"
  [ -f "$_config" ] || return 0
  if grep -q '^[[:space:]]*"name"[[:space:]]*:' "$_config"; then
    sed -i "s|^[[:space:]]*\"name\"[[:space:]]*:.*|  \"name\": \"${_namespace}\",|" "$_config"
  else
    sed -i "1a\\  \"name\": \"${_namespace}\"," "$_config"
  fi
}

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
  ensure_waybar_namespace "$(paths_config taskbar/config/argvus-taskbar.jsonc 2>/dev/null || true)" argvus-taskbar
  [ -f "$_css" ] || return 0
  if ! grep -q '^@define-color th-background-effective ' "$_css"; then
    sed -i '/^@define-color transparent transparent;$/a @define-color th-background-effective @th-background-rgba;' "$_css"
    sed -i 's/background: @th-background-rgba;/background: @th-background-effective;/' "$_css"
  fi
  if ! grep -q '^@define-color th-mpris-bg-effective ' "$_css"; then
    sed -i '/^@define-color th-background-effective /a @define-color th-mpris-bg-effective @th-mpris-bg;' "$_css"
    sed -i 's/background: @th-mpris-bg;/background: @th-mpris-bg-effective;/' "$_css"
  fi
  if [ "$(effect_enabled taskbar.transparency)" = disabled ]; then
    sed -i 's/^@define-color th-background-effective .*/@define-color th-background-effective @th-background;/' "$_css"
    sed -i 's/^@define-color th-mpris-bg-effective .*/@define-color th-mpris-bg-effective @th-right1-bg;/' "$_css"
  else
    _opacity="$(opacity_factor "$(effect_value taskbar.transparency)")"
    sed -i "s|^@define-color th-background-effective .*|@define-color th-background-effective alpha(@th-background, ${_opacity});|" "$_css"
    sed -i "s|^@define-color th-mpris-bg-effective .*|@define-color th-mpris-bg-effective alpha(@th-mpris-bg, ${_opacity});|" "$_css"
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
    dracula|dracula-float) printf '#282A36\n' ;;
    slate-dark|slate-dark-float) printf '#2f3541\n' ;;
    argvus-light|argvus-light-float) printf '#f7f7f7\n' ;;
    github-light|github-light-float) printf '#ffffff\n' ;;
    one-light|one-light-float) printf '#FAFAFA\n' ;;
    everforest-light|everforest-light-float) printf '#FDF6E3\n' ;;
    solarized-light|solarized-light-float) printf '#FDF6E3\n' ;;
    frost|frost-float) printf '#f6f8fa\n' ;;
    catppuccin-latte|catppuccin-latte-float) printf '#EFF1F5\n' ;;
    gruvbox-light|gruvbox-light-float) printf '#FBF1C7\n' ;;
    universe|universe-float) printf '#000000\n' ;;
    gruvbox-high-dark|gruvbox-high-dark-float|gruvbox-dark|gruvbox-dark-float) printf '#282828\n' ;;
    solitude|solitude-float) printf '#101315\n' ;;
    sunset|sunset-float) printf '#0F0F0F\n' ;;
    hackerman|hackerman-float) printf '#0B0C16\n' ;;
    monokai-dark|monokai-dark-float) printf '#2D2A2E\n' ;;
    one-dark|one-dark-float) printf '#282C34\n' ;;
    *) printf '#111316\n' ;;
  esac
}

apply_widget_telemetry_surface() {
  _css="$(paths_config widget-telemetry/config/argvus-widget-telemetry.css 2>/dev/null || true)"
  ensure_waybar_namespace "$(paths_config widget-telemetry/config/argvus-widget-telemetry.jsonc 2>/dev/null || true)" argvus-widget-telemetry
  [ -f "$_css" ] || return 0
  if ! grep -q '^@define-color th-window-bg-effective ' "$_css"; then
    sed -i '/^\/\*  Waybar — Painel vertical/a @define-color th-window-bg-effective @th-window-bg-rgba;' "$_css"
    sed -i 's/background: @th-window-bg;/background: @th-window-bg-effective;/' "$_css"
  fi
  if [ "$(effect_enabled widget-telemetry.transparency)" = disabled ]; then
    sed -i 's/^@define-color th-window-bg-effective .*/@define-color th-window-bg-effective @th-window-bg;/' "$_css"
  else
    _opacity="$(opacity_factor "$(effect_value widget-telemetry.transparency)")"
    sed -i "s|^@define-color th-window-bg-effective .*|@define-color th-window-bg-effective alpha(@th-window-bg, ${_opacity});|" "$_css"
  fi
}

apply_launcher_surface() {
  _theme="$(paths_config launcher/config/theme.rasi 2>/dev/null || true)"
  [ -f "$_theme" ] || return 0
  if [ "$(effect_enabled launchers.transparency)" = disabled ]; then
    _background="$(theme_background)"
  else
    _opacity="$(opacity_factor "$(effect_value launchers.transparency)")"
    _import="$(sed -n 's/^@import "\([^"]*\)".*/\1/p' "$_theme" | head -n1)"
    _color="$(sed -n 's/^[[:space:]]*th-bg:[[:space:]]*\(.*\);/\1/p' "$_import" 2>/dev/null | head -n1)"
    _channels="$(printf '%s\n' "$_color" | sed -E 's/rgba?[[:space:]]*\(|\)|%//g; s/,/ /g')"
    # Intentional word splitting: the channel components must become $1..$n.
    # shellcheck disable=SC2086
    set -- $_channels
    case "$#" in
      3|4)
        _alpha="$(awk -v opacity="$_opacity" 'BEGIN { printf "%.0f", opacity * 100 }')"
        _background="rgba($1, $2, $3, ${_alpha}%)"
        ;;
      *)
        _background='@th-bg'
        ;;
    esac
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
  apply_taskbar_surface "$_animations_status"
  apply_widget_telemetry_surface
  apply_launcher_surface
  apply_dunst_surface "$_transparency_status"
  apply_calendar_surface "$_transparency_status"
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

canonical_status() {
  _component="$1"
  command -v argvus-config >/dev/null 2>&1 || return 1
  _value="$(argvus-config get "/effects/${_component}" --effective --raw 2>/dev/null || true)"
  case "$_value" in
    true|enabled) printf 'enabled\n' ;;
    false|disabled) printf 'disabled\n' ;;
    *) return 1 ;;
  esac
}

canonical_explicit_status() {
  _component="$1"
  command -v argvus-config >/dev/null 2>&1 || return 1
  _value="$(argvus-config get "/effects/${_component}" --raw 2>/dev/null || true)"
  case "$_value" in
    true|enabled) printf 'enabled\n' ;;
    false|disabled) printf 'disabled\n' ;;
    *) return 1 ;;
  esac
}

status() {
  _component="$1"
  [ "$_component" = blur ] && { global_effect_enabled; return; }
  # Animations are canonical in config.json. The legacy state file remains a
  # migration fallback only, so a stale generated marker can never override
  # the Control Center/Control Panel setting.
  if [ "$_component" = animations ] && canonical_explicit_status "$_component"; then
    return 0
  fi
  _state_file="$(state_file "$_component")"
  case "$(sed -n '1p' "$_state_file" 2>/dev/null || true)" in
    enabled|disabled) sed -n '1p' "$_state_file" ;;
    *) canonical_status "$_component" || legacy_status ;;
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
}

# Regenerates the dedicated Kitty backing store for the Control Center TUI and
# asks running instances to reload it. Kitty rebuilds the generated config on
# SIGUSR1, so the transparency and blur settings apply live.
rematerialize_control_center() {
  command -v argvus-tui-terminal >/dev/null 2>&1 && argvus-tui-terminal --materialize-kitty --profile control-center --class argvus-control-center >/dev/null 2>&1 || true
  for _pid in $(pgrep -x kitty 2>/dev/null); do
    kill -USR1 "$_pid" 2>/dev/null || true
  done
}

set_status() {
  _component="$1"
  _status="$2"
  if [ "$_component" = blur ] && command -v argvus-config >/dev/null 2>&1; then
    argvus-config set /effects/blur_global_enabled "$([ "$_status" = enabled ] && printf true || printf false)"
    request_config_reload || return 1
    apply_surfaces "$(status transparency)" "$(status animations)"
    printf '%s\n' "$_status"
    apply_runtime >/dev/null 2>&1 &
    return 0
  fi
  if [ "$_component" = animations ] && command -v argvus-config >/dev/null 2>&1; then
    argvus-config set /effects/animations "$([ "$_status" = enabled ] && printf true || printf false)"
    request_config_reload || return 1
    _state_file="$(state_file "$_component")"
    mkdir -p "${_state_file%/*}"
    printf '%s\n' "$_status" > "$_state_file"
    apply_surfaces "$(status transparency)" "$_status"
    printf '%s\n' "$_status"
    apply_runtime >/dev/null 2>&1 &
    return 0
  fi
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
  printf '%s\n' "$_status" > "$(state_file blur)"
  config_set_flag /effects/animations "$_status"
  request_config_reload || return 1
  apply_surfaces "$_status" "$_status"
  printf '%s\n' "$_status"
  apply_runtime >/dev/null 2>&1 &
}

surface_value_command() {
  _kind="$1"
  _surface="$2"
  _operation="${3:-get}"
  case "$_surface" in
    taskbar|control-panel|widget-telemetry|terminal|launchers|control-center) ;;
    *) exit 64 ;;
  esac
  if [ "$_surface" = control-center ]; then
    [ "$_kind" = transparency ] || exit 64
    case "$_operation" in
      get)
        command -v argvus-config >/dev/null 2>&1 || exit 64
        _value="$(argvus-config get /effects/transparency_control-center_value --effective --raw 2>/dev/null || true)"
        case "$_value" in
          ''|*[!0-9]*) printf '50\n' ;;
          *) [ "$_value" -le 100 ] && printf '%s\n' "$_value" || printf '50\n' ;;
        esac
        ;;
      set)
        case "${4:-}" in ''|*[!0-9]*) exit 64 ;; esac
        [ "${4:-}" -le 100 ] || exit 64
        command -v argvus-config >/dev/null 2>&1 || exit 64
        argvus-config set /effects/transparency_control-center_value "${4:-}" || exit 1
        request_config_reload || exit 1
        rematerialize_control_center
        printf '%s\n' "${4:-}"
        ;;
      *) exit 64 ;;
    esac
    return 0
  fi
  _key="${_surface}.${_kind}"
  case "$_operation" in
    get) effect_value "$_key" ;;
    set)
      set_effect_value "$_key" "${4:-}" || exit 64
      request_config_reload || exit 1
      apply_surfaces "$(status transparency)" "$(status animations)"
      printf '%s\n' "$(effect_value "$_key")"
      apply_runtime >/dev/null 2>&1 &
      ;;
    *) exit 64 ;;
  esac
}

global_value_command() {
  _key="$1"
  _operation="${2:-get}"
  case "$_key" in blur_global_value) ;; *) exit 64 ;; esac
  case "$_operation" in
    get) global_effect_value "$_key" ;;
    set)
      _value="${3:-}"
      case "$_value" in ''|*[!0-9]*) exit 64 ;; esac
      [ "$_value" -le 100 ] || exit 64
      command -v argvus-config >/dev/null 2>&1 || exit 64
      argvus-config set "/effects/${_key}" "$_value" || exit 1
      request_config_reload || exit 1
      printf '%s\n' "$_value"
      apply_runtime >/dev/null 2>&1 &
      ;;
    *) exit 64 ;;
  esac
}

surface_apply_command() {
  _surface="$1"
  _transparency_enabled="$2"
  _transparency_value="$3"
  _blur_enabled="$4"
  _blur_value="$5"
  case "$_surface" in
    taskbar|control-panel|widget-telemetry|terminal|launchers|control-center) ;;
    *) exit 64 ;;
  esac
  case "$_transparency_enabled" in enabled|disabled) ;; *) exit 64 ;; esac
  case "$_blur_enabled" in enabled|disabled) ;; *) exit 64 ;; esac
  case "$_transparency_value" in ''|*[!0-9]*) exit 64 ;; esac
  case "$_blur_value" in ''|*[!0-9]*) exit 64 ;; esac
  [ "$_transparency_value" -le 100 ] || exit 64
  [ "$_blur_value" -le 100 ] || exit 64
  if [ "$_surface" = control-center ]; then
    command -v argvus-config >/dev/null 2>&1 || exit 64
    argvus-config set /effects/transparency_control-center_enabled "$([ "$_transparency_enabled" = enabled ] && printf true || printf false)" || exit 1
    argvus-config set /effects/transparency_control-center_value "$_transparency_value" || exit 1
    argvus-config set /effects/blur_control-center_enabled "$([ "$_blur_enabled" = enabled ] && printf true || printf false)" || exit 1
    request_config_reload || exit 1
    rematerialize_control_center
    printf '%s\n' "$_transparency_value"
    exit 0
  fi
  if [ "$_surface" = terminal ]; then
    command -v argvus-config >/dev/null 2>&1 || exit 64
    argvus-config set /effects/transparency_terminal_enabled "$([ "$_transparency_enabled" = enabled ] && printf true || printf false)" || exit 1
    argvus-config set /effects/transparency_terminal_value "$_transparency_value" || exit 1
    _pointer="$(config_enabled_key terminal blur)"
    [ -n "$_pointer" ] && config_set_flag "$_pointer" "$_blur_enabled"
    _theme="$(sed -n '1p' "${ARGVUS_CONFIG_HOME}/argvus/.active-theme" 2>/dev/null || true)"
    command -v argvus-terminal >/dev/null 2>&1 && argvus-terminal --apply "$_theme" >/dev/null 2>&1 || true
    for _pid in $(pgrep -x kitty 2>/dev/null); do kill -USR1 "$_pid" 2>/dev/null || true; done
    request_config_reload || exit 1
    printf '%s\n' "$_transparency_value"
    exit 0
  fi
  if [ "$_surface" = launchers ]; then
    ensure_theme_effects
    _file="$(theme_effects_file)"
    _tmp="${_file}.tmp.$$"
    awk -F= -v surface="$_surface" \
      -v transparency_enabled="$_transparency_enabled" \
      -v transparency_value="$_transparency_value" '
      BEGIN {
        keys[1] = surface ".transparency.enabled"; values[1] = transparency_enabled
        keys[2] = surface ".transparency"; values[2] = transparency_value
      }
      {
        replaced = 0
        for (slot = 1; slot <= 2; slot++) {
          if ($1 == keys[slot]) { print keys[slot] "=" values[slot]; seen[slot] = 1; replaced = 1; break }
        }
        if (!replaced) print
      }
      END {
        for (slot = 1; slot <= 2; slot++) if (!seen[slot]) print keys[slot] "=" values[slot]
      }
    ' "$_file" > "$_tmp" && mv -f "$_tmp" "$_file"
    _pointer="$(config_enabled_key launchers transparency)"
    [ -n "$_pointer" ] && config_set_flag "$_pointer" "$_transparency_enabled"
    _pointer="$(config_value_key launchers)"
    [ -n "$_pointer" ] && config_set_value "$_pointer" "$_transparency_value"
    request_config_reload || exit 1
    apply_launcher_surface
    printf '%s\n' "$_transparency_value"
    exit 0
  fi
  ensure_theme_effects
  _file="$(theme_effects_file)"
  _tmp="${_file}.tmp.$$"
  awk -F= -v surface="$_surface" \
    -v transparency_enabled="$_transparency_enabled" \
    -v transparency_value="$_transparency_value" \
    -v blur_enabled="$_blur_enabled" -v blur_value="$_blur_value" '
    BEGIN {
      keys[1] = surface ".transparency.enabled"; values[1] = transparency_enabled
      keys[2] = surface ".transparency"; values[2] = transparency_value
      keys[3] = surface ".blur.enabled"; values[3] = blur_enabled
      keys[4] = surface ".blur"; values[4] = blur_value
    }
    {
      replaced = 0
      for (slot = 1; slot <= 4; slot++) {
        if ($1 == keys[slot]) { print keys[slot] "=" values[slot]; seen[slot] = 1; replaced = 1; break }
      }
      if (!replaced) print
    }
    END {
      for (slot = 1; slot <= 4; slot++) if (!seen[slot]) print keys[slot] "=" values[slot]
    }
  ' "$_file" > "$_tmp" && mv -f "$_tmp" "$_file"
  _pointer="$(config_enabled_key "$_surface" transparency)"
  [ -n "$_pointer" ] && config_set_flag "$_pointer" "$_transparency_enabled"
  _pointer="$(config_value_key "$_surface")"
  [ -n "$_pointer" ] && config_set_value "$_pointer" "$_transparency_value"
  _pointer="$(config_enabled_key "$_surface" blur)"
  [ -n "$_pointer" ] && config_set_flag "$_pointer" "$_blur_enabled"
  request_config_reload || return 1
  apply_taskbar_surface "$(status animations)"
  apply_widget_telemetry_surface
  if command -v hyprctl >/dev/null 2>&1; then hyprctl reload >/dev/null 2>&1 || true; fi
  case "$_surface" in
    taskbar) command -v argvus-sessionctl >/dev/null 2>&1 && argvus-sessionctl restart waybar >/dev/null 2>&1 || true ;;
    widget-telemetry) command -v argvus-sessionctl >/dev/null 2>&1 && argvus-sessionctl restart widget-telemetry >/dev/null 2>&1 || true ;;
    control-panel) command -v argvus-sessionctl >/dev/null 2>&1 && argvus-sessionctl restart control-panel >/dev/null 2>&1 || true ;;
  esac
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
  animations|transparency|blur)
    component_command "$1" "${2:-status}"
    ;;
  transparency-value|blur-value)
    surface_value_command "${1%-value}" "${2:-}" "${3:-get}" "${4:-}"
    ;;
  global-value)
    global_value_command "${2:-}" "${3:-get}" "${4:-}"
    ;;
  surface-apply)
    surface_apply_command "${2:-}" "${3:-}" "${4:-}" "${5:-}" "${6:-}"
    ;;
  effect-enabled)
    case "${2:-}" in
      taskbar|control-panel|widget-telemetry|terminal|launchers) effect_enabled "${2}.${3:-}" ;;
      control-center)
        command -v argvus-config >/dev/null 2>&1 || exit 64
        _value="$(argvus-config get "/effects/${3:-}_control-center_enabled" --effective --raw 2>/dev/null || true)"
        case "$_value" in
          true|enabled) printf 'enabled\n' ;;
          false|disabled) printf 'disabled\n' ;;
          *) printf 'enabled\n' ;;
        esac
        ;;
      *) exit 64 ;;
    esac
    ;;
  status)
    # Legacy aggregate status: enabled only when both independent settings are
    # enabled. New callers should request a component explicitly.
    if [ "$(status animations)" = enabled ] &&
      [ "$(status transparency)" = enabled ] &&
      [ "$(status blur)" = enabled ]; then
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
    ensure_theme_effects
    apply_surfaces "$(status transparency)" "$(status animations)"
    ;;
  *)
    argvus_tr session usage.effects "command=${0##*/}" >&2
    exit 64
    ;;
esac
