#!/usr/bin/env sh

# shellcheck disable=SC1091
. /usr/share/argvus/lib/i18n.sh
#
# Daemon that shows a notification when the keyboard layout changes.
#
# Works on any machine: it listens to Hyprland's "activelayout" IPC events and
# notifies once per change, ignoring virtual/control/mouse devices.
#
# Started automatically by init.sh --started.

# Resolve the Hyprland instance socket regardless of session specifics.
SIG="${HYPRLAND_INSTANCE_SIGNATURE:-}"
if [ -z "$SIG" ]; then
  SIG="$(hyprctl instances -j 2>/dev/null | jq -r '.[0].instance' 2>/dev/null)"
fi
SOCKET="${XDG_RUNTIME_DIR:-/tmp}/hypr/${SIG}/.socket2.sock"

if [ ! -S "$SOCKET" ]; then
  printf 'keyboard-layout-daemon: IPC socket not found (%s)\n' "$SOCKET" >&2
  exit 1
fi

# Resolve the active XKB code from the device, keeping the event label as fallback.
layout_code() {
  _code="$(hyprctl devices -j 2>/dev/null | jq -r --arg device "$1" '
    .keyboards[] | select(.name == $device) | . as $keyboard
    | ($keyboard.layout // "" | split(","))[$keyboard.active_layout_index // 0]
    // empty
  ' 2>/dev/null)" || _code=""
  if [ -n "$_code" ]; then
    printf '%s' "$_code"
  else
    printf '%s' "$2"
  fi
}

ARGVUS_CACHE_HOME="${ARGVUS_CACHE_HOME:-${XDG_CACHE_HOME:-$HOME/.cache}/argvus}"
SUPPRESS_FILE="$ARGVUS_CACHE_HOME/hypr/keyboard-layout-notify.suppress"

notifications_suppressed() {
  [ -f "$SUPPRESS_FILE" ] || return 1
  stamp="$(sed -n '1p' "$SUPPRESS_FILE" 2>/dev/null || true)"
  case "$stamp" in
    ''|*[!0-9]*) rm -f "$SUPPRESS_FILE"; return 1 ;;
  esac
  now="$(date +%s)"
  if [ $((now - stamp)) -le 10 ]; then
    return 0
  fi
  rm -f "$SUPPRESS_FILE"
  return 1
}

last=""
# Listen for layout events, coalescing the burst emitted per keyboard.
socat -u "UNIX-CONNECT:${SOCKET}" - 2>/dev/null \
  | grep --line-buffered 'activelayout>>' \
  | while IFS= read -r line; do
      dev="${line#*>>}"; dev="${dev%%,*}"
      layout="${line##*,}"
      # Skip virtual/control/mouse/audio devices so we notify only once.
      case "$dev" in
        *power*|*sleep*|*system-control*|*consumer-control*|*mouse*|*audio-device*) continue ;;
      esac
      if notifications_suppressed; then
        last="$layout"
        continue
      fi
      if [ "$layout" != "$last" ]; then
        last="$layout"
        title="$(argvus_tr session keyboard.layout.title)"
        code="$(layout_code "$dev" "$layout")"
        notify-send --app-name="$title" --icon=input-keyboard "$title" \
          "$(argvus_tr session keyboard.layout.changed "layout=$code")"
        # Coalesce the burst emitted simultaneously by several keyboards.
        sleep 0.2
      fi
    done
