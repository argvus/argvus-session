#!/usr/bin/env sh

# shellcheck disable=SC1091
ARGVUS_BOOTSTRAP="${ARGVUS_BOOTSTRAP:-${ARGVUS_SYSTEM_CONFIG:-/usr/share/argvus}/session/sh/bootstrap.sh}"
. "$ARGVUS_BOOTSTRAP"

STATE_FILE="$(paths_state effects)"

detect_vm() {
  if command -v systemd-detect-virt >/dev/null 2>&1; then
    systemd-detect-virt --vm >/dev/null 2>&1
    return $?
  fi

  return 1
}

default_status() {
  if [ "${ARGVUS_LOW_POWER:-0}" = "1" ] || detect_vm; then
    printf 'disabled\n'
  else
    printf 'enabled\n'
  fi
}

status() {
  case "$(sed -n '1p' "$STATE_FILE" 2>/dev/null || true)" in
    enabled) printf 'enabled\n' ;;
    disabled) printf 'disabled\n' ;;
    *) default_status ;;
  esac
}

apply_runtime() {
  if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
  fi

  if command -v argvus-sessionctl >/dev/null 2>&1; then
    argvus-sessionctl restart control-panel >/dev/null 2>&1 || true
  fi
}

set_status() {
  _status="$1"
  mkdir -p "${STATE_FILE%/*}"
  printf '%s\n' "$_status" > "$STATE_FILE"
  printf '%s\n' "$_status"
  apply_runtime >/dev/null 2>&1 &
}

case "${1:-status}" in
  status)
    status
    ;;
  enable|on|enabled)
    set_status enabled
    ;;
  disable|off|disabled)
    set_status disabled
    ;;
  toggle)
    case "$(status)" in
      enabled) set_status disabled ;;
      *) set_status enabled ;;
    esac
    ;;
  *)
    argvus_tr session usage.effects "command=${0##*/}" >&2
    exit 64
    ;;
esac
