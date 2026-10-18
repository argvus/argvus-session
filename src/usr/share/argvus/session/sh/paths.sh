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
  # The copy rules (component, flat, generated and waybar shim promotion) live
  # in argvus-config, so the shell has one implementation. argvus-config is a
  # dependency of this package and is called from the commands directory, as
  # the session scripts do.
  "${ARGVUS_COMMANDS_DIR:-/usr/lib/argvus/commands}/argvus-config" mutable-path "$1"
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
