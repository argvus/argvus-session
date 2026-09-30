# shellcheck shell=sh disable=SC2034

# -- Path helpers -------------------------------------------------------------
#
# The user configuration root holds exactly two entries: `config/`, the canonical
# modular document, and `data/`, everything the desktop writes at runtime. Every
# managed component tree, generated file and state marker therefore lives under
# `data/`. `paths_user_config` is the single place that decides that mapping.

ARGVUS_SYSTEM_CONFIG="${ARGVUS_SYSTEM_CONFIG:-/usr/share/argvus}"
ARGVUS_CONFIG_HOME="${ARGVUS_CONFIG_HOME:-${XDG_CONFIG_HOME:-$HOME/.config}}"
ARGVUS_DATA_HOME="${ARGVUS_DATA_HOME:-${ARGVUS_CONFIG_HOME}/argvus/data}"
ARGVUS_STATE_HOME="${ARGVUS_STATE_HOME:-${ARGVUS_DATA_HOME}/state}"
ARGVUS_CACHE_HOME="${ARGVUS_CACHE_HOME:-${XDG_CACHE_HOME:-$HOME/.cache}/argvus}"

paths_legacy_relative() {
  case "$1" in
    power/config/hypridle.conf|lock/config/hyprlock.conf)
      printf 'hypr/%s\n' "${1##*/}"
      ;;
    taskbar/config/*|widget-telemetry/config/*)
      printf 'waybar/%s\n' "${1#*/config/}"
      ;;
    removable-devices/config/*)
      printf 'removable-devices/%s\n' "${1#*/config/}"
      ;;
    taskbar-storage/config/*)
      printf 'taskbar/storage/%s\n' "${1#*/config/}"
      ;;
    launcher/config/*)
      printf 'rofi/%s\n' "${1#*/config/}"
      ;;
    notifications/config/*)
      printf 'dunst/%s\n' "${1#*/config/}"
      ;;
    control-panel/config/quickshell/*)
      printf 'quickshell/%s\n' "${1#control-panel/config/quickshell/}"
      ;;
    appearance/config/*)
      printf '%s\n' "${1#appearance/config/}"
      ;;
    app-profiles/config/*)
      printf '%s\n' "${1#app-profiles/config/}"
      ;;
    hyprland/sh/*)
      printf 'scripts/argvus/%s\n' "${1##*/}"
      ;;
    */sh/*)
      printf 'scripts/argvus/%s\n' "${1##*/}"
      ;;
    *)
      printf '%s\n' "$1"
      ;;
  esac
}

paths_user_config() {
  _legacy_relative_path="$(paths_legacy_relative "$1")"
  echo "${ARGVUS_DATA_HOME}/${_legacy_relative_path}"
}
paths_legacy_user_config() {
  _legacy_relative_path="$(paths_legacy_relative "$1")"
  echo "${ARGVUS_CONFIG_HOME}/argvus/${_legacy_relative_path}"
}
paths_override_config() {
  _legacy_relative_path="$(paths_legacy_relative "$1")"
  echo "${ARGVUS_CONFIG_HOME}/${_legacy_relative_path}"
}
paths_system_config() { echo "${ARGVUS_SYSTEM_CONFIG}/${1}"; }
paths_generated_config() {
  _legacy_relative_path="$(paths_legacy_relative "$1")"
  echo "${ARGVUS_DATA_HOME}/generated/${_legacy_relative_path}"
}
paths_cache() { echo "${ARGVUS_CACHE_HOME}/${1}"; }
paths_state() { echo "${ARGVUS_STATE_HOME}/${1}"; }
paths_data() { echo "${ARGVUS_DATA_HOME}/${1}"; }
paths_backgrounds() { echo "${ARGVUS_BACKGROUNDS_DIR:-/usr/share/backgrounds}/${1}"; }

paths_read_config() {
  _relative_path="$1"
  _user_path="$(paths_user_config "$_relative_path")"
  _override_path="$(paths_override_config "$_relative_path")"
  _generated_path="$(paths_generated_config "$_relative_path")"
  _system_path="$(paths_system_config "$_relative_path")"

  # Also accept the component-shaped and the pre-`data/` user copies created by
  # earlier layouts. Keep native overrides ahead of managed user and generated
  # configuration.
  for _candidate in \
    "$_override_path" "$ARGVUS_CONFIG_HOME/$_relative_path" \
    "$_user_path" "$(paths_legacy_user_config "$_relative_path")" \
    "$ARGVUS_CONFIG_HOME/argvus/$_relative_path" \
    "$_generated_path" "$ARGVUS_CONFIG_HOME/argvus/data/generated/$_relative_path"; do
    if [ -e "$_candidate" ] || [ -L "$_candidate" ]; then
      printf '%s\n' "$_candidate"
      return 0
    fi
  done
  printf '%s\n' "$_system_path"
}

paths_ensure_generated_copy() {
  _relative_path="$1"
  _user_path="$(paths_user_config "$_relative_path")"
  _generated_path="$(paths_generated_config "$_relative_path")"

  if [ -e "$_user_path" ] || [ -L "$_user_path" ]; then
    printf '%s\n' "$_user_path"
    return 0
  fi

  # Retain edits from the component-shaped managed layout. Copy instead of
  # moving so older installed consumers can still read the previous location.
  _component_user_path="$ARGVUS_CONFIG_HOME/argvus/$_relative_path"
  if [ "$_component_user_path" != "$_user_path" ] && [ -f "$_component_user_path" ]; then
    mkdir -p "${_user_path%/*}"
    cp "$_component_user_path" "$_user_path" || return 1
    printf '%s\n' "$_user_path"
    return 0
  fi

  # Promote the pre-`data/` flat managed copy so an upgraded profile keeps its
  # user edits at the new location.
  _flat_user_path="$(paths_legacy_user_config "$_relative_path")"
  if [ "$_flat_user_path" != "$_user_path" ] && [ -f "$_flat_user_path" ]; then
    mkdir -p "${_user_path%/*}"
    cp "$_flat_user_path" "$_user_path" || return 1
    printf '%s\n' "$_user_path"
    return 0
  fi

  # Read-only lookup also accepts component-shaped generated files. Promote
  # those through the same migration/shim handling rather than losing edits.
  if [ ! -e "$_generated_path" ] && [ ! -L "$_generated_path" ]; then
    _component_generated_path="$ARGVUS_CONFIG_HOME/argvus/data/generated/$_relative_path"
    if [ -e "$_component_generated_path" ] || [ -L "$_component_generated_path" ]; then
      _generated_path="$_component_generated_path"
    fi
  fi

  # Migrate: if generated copy exists but user path doesn't, move it to user path
  if [ -e "$_generated_path" ] || [ -L "$_generated_path" ]; then
    # A settings-managed CSS shim (an @import wrapper to the system css) must
    # not be promoted to the user copy: the user copy is the themed css that
    # theme-switch rewrites per theme. Retire the shim and use the system css.
    _legacy_relative_path="$(paths_legacy_relative "$_relative_path")"
    case "$_legacy_relative_path" in
      waybar/*.css)
        _first_line="$(sed -n '1p' "$_generated_path" 2>/dev/null || true)"
        case "$_first_line" in
          '@import url("/usr/'*)
            _system_path="$(paths_system_config "$_relative_path")"
            if [ -f "$_system_path" ]; then
              mv "$_generated_path" "${_generated_path}.retired"
              mkdir -p "${_user_path%/*}"
              cp "$_system_path" "$_user_path"
              printf '%s\n' "$_user_path"
              return 0
            fi
            ;;
        esac
        ;;
    esac
    _parent="${_user_path%/*}"
    mkdir -p "$_parent"
    mv "$_generated_path" "$_user_path"
    printf '%s\n' "$_user_path"
    return 0
  fi

  _system_path="$(paths_system_config "$_relative_path")"
  _source_path="$_system_path"

  if [ -d "$_source_path" ]; then
    mkdir -p "$_user_path"
    cp -R "$_source_path/." "$_user_path/"
  elif [ -f "$_source_path" ]; then
    mkdir -p "${_user_path%/*}"
    cp "$_source_path" "$_user_path"
  else
    mkdir -p "${_user_path%/*}"
  fi

  printf '%s\n' "$_user_path"
}

paths_config() {
  _relative_path="$1"

  if [ "${ARGVUS_MUTABLE_CONFIG:-0}" = 1 ]; then
    case "$_relative_path" in
      sh/*|*/sh/*|docs/*|*/docs/*)
        paths_read_config "$_relative_path"
        return 0
      ;;
    esac
    paths_ensure_generated_copy "$_relative_path"
    return 0
  fi

  paths_read_config "$_relative_path"
}
