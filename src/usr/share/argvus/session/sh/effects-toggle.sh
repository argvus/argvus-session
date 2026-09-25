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
  [ -f "$_file" ] && return 0
  mkdir -p "${_file%/*}"
  {
    printf '%s\n' 'taskbar.transparency=50'
    printf '%s\n' 'control-panel.transparency=50'
    printf '%s\n' 'widget-telemetry.transparency=50'
    printf '%s\n' 'taskbar.transparency.enabled=enabled'
    printf '%s\n' 'control-panel.transparency.enabled=enabled'
    printf '%s\n' 'widget-telemetry.transparency.enabled=enabled'
    printf '%s\n' 'taskbar.blur=50'
    printf '%s\n' 'control-panel.blur=50'
    printf '%s\n' 'widget-telemetry.blur=50'
    printf '%s\n' 'taskbar.blur.enabled=enabled'
    printf '%s\n' 'control-panel.blur.enabled=enabled'
    printf '%s\n' 'widget-telemetry.blur.enabled=enabled'
  } > "$_file"
}

effect_value() {
  _key="$1"
  ensure_theme_effects
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
    sed -i '/^\/\*  Waybar — Painel vertical/a @define-color th-window-bg-effective @th-window-bg;' "$_css"
    sed -i 's/background: @th-window-bg;/background: @th-window-bg-effective;/' "$_css"
  fi
  if [ "$(effect_enabled widget-telemetry.transparency)" = disabled ]; then
    sed -i 's/^@define-color th-window-bg-effective .*/@define-color th-window-bg-effective @th-background;/' "$_css"
  else
    _opacity="$(opacity_factor "$(effect_value widget-telemetry.transparency)")"
    sed -i "s|^@define-color th-window-bg-effective .*|@define-color th-window-bg-effective alpha(@th-window-bg, ${_opacity});|" "$_css"
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
  [ -n "$_theme" ] || _theme='argvus-dark'
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
  apply_taskbar_surface "$_animations_status"
  apply_widget_telemetry_surface
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
  printf '%s\n' "$_status" > "$(state_file blur)"
  apply_surfaces "$_status" "$_status"
  printf '%s\n' "$_status"
  apply_runtime >/dev/null 2>&1 &
}

surface_value_command() {
  _kind="$1"
  _surface="$2"
  _operation="${3:-get}"
  case "$_surface" in
    taskbar|control-panel|widget-telemetry) ;;
    *) exit 64 ;;
  esac
  _key="${_surface}.${_kind}"
  case "$_operation" in
    get) effect_value "$_key" ;;
    set)
      set_effect_value "$_key" "${4:-}" || exit 64
      apply_surfaces "$(status transparency)" "$(status animations)"
      printf '%s\n' "$(effect_value "$_key")"
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
    taskbar|control-panel|widget-telemetry) ;;
    *) exit 64 ;;
  esac
  case "$_transparency_enabled" in enabled|disabled) ;; *) exit 64 ;; esac
  case "$_blur_enabled" in enabled|disabled) ;; *) exit 64 ;; esac
  case "$_transparency_value" in ''|*[!0-9]*) exit 64 ;; esac
  case "$_blur_value" in ''|*[!0-9]*) exit 64 ;; esac
  [ "$_transparency_value" -le 100 ] || exit 64
  [ "$_blur_value" -le 100 ] || exit 64
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
  surface-apply)
    surface_apply_command "${2:-}" "${3:-}" "${4:-}" "${5:-}" "${6:-}"
    ;;
  effect-enabled)
    case "${2:-}" in
      taskbar|control-panel|widget-telemetry) effect_enabled "${2}.${3:-}" ;;
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
