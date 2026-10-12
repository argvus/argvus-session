# shellcheck shell=sh
ARGVUS_COMMANDS_DIR="${ARGVUS_COMMANDS_DIR:-/usr/lib/argvus/commands}"

locale_detect() {
  if [ -x "$ARGVUS_COMMANDS_DIR/argvus-i18n" ]; then
    "$ARGVUS_COMMANDS_DIR/argvus-i18n" locale
    return
  fi
  case "$LC_ALL:$LC_MESSAGES:$LANG" in
    pt*:*:*|*:pt*:*|*:*:pt*) printf '%s\n' "pt-BR" ;;
    *) printf '%s\n' "en-US" ;;
  esac
}

locale_is_pt() {
  case "$(locale_detect)" in
    pt*) return 0 ;;
    *) return 1 ;;
  esac
}

argvus_tr() {
  if [ -x "$ARGVUS_COMMANDS_DIR/argvus-i18n" ]; then
    "$ARGVUS_COMMANDS_DIR/argvus-i18n" get "$@"
    return
  fi
  printf '%s\n' "$2"
}
