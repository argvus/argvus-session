# shellcheck shell=sh
ARGVUS_COMMANDS_DIR="${ARGVUS_COMMANDS_DIR:-/usr/lib/argvus/commands}"

# Read assignments as data, never source a user-owned configuration as code.
locale_user_settings() {
  _locale_config="${XDG_CONFIG_HOME:-$HOME/.config}/locale.conf"
  [ -r "$_locale_config" ] || return 0
  awk '
    /^[[:space:]]*#/ { next }
    {
      position = index($0, "=")
      if (!position) next
      key = substr($0, 1, position - 1)
      sub(/^[[:space:]]+/, "", key)
      if (key !~ /^(LANG|LC_CTYPE|LC_NUMERIC|LC_TIME|LC_COLLATE|LC_MONETARY|LC_PAPER|LC_NAME|LC_ADDRESS|LC_TELEPHONE|LC_MEASUREMENT|LC_IDENTIFICATION)$/) next
      value = substr($0, position + 1)
      sub(/^[[:space:]]+/, "", value)
      sub(/[[:space:]]+$/, "", value)
      gsub(/^["\047]|["\047]$/, "", value)
      if (value != "null" && value ~ /^[a-zA-Z0-9_.@-]+$/) print key "=" value
    }
  ' "$_locale_config"
}

locale_user_lang() {
  locale_user_settings | awk -F= '
    $1 == "LANG" { language = $2 }
    END { print language != "" ? language : "en_US.UTF-8" }
  '
}

# Call before importing the environment or starting any desktop component.
locale_apply() {
  LANG="$(locale_user_lang)"
  _locale_available="$(locale -a 2>/dev/null | tr '[:upper:]' '[:lower:]' | tr -d '-')"
  _locale_requested="$(printf '%s' "$LANG" | tr '[:upper:]' '[:lower:]' | tr -d '-')"
  if ! printf '%s\n' "$_locale_available" | grep -Fxiq -- "$_locale_requested"; then
    if printf '%s\n' "$_locale_available" | grep -Fxiq 'en_us.utf8'; then
      LANG=en_US.UTF-8
    else
      LANG=C.UTF-8
    fi
  fi
  # Empty values also clear stale variables in the D-Bus activation environment.
  export LANG LC_ALL='' LC_MESSAGES="$LANG" LANGUAGE="${LANG%%.*}"
  for _locale_category in LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT LC_IDENTIFICATION; do
    export "$_locale_category="
  done
  while IFS='=' read -r _locale_category _locale_value; do
    case "$_locale_category" in
      LC_CTYPE|LC_NUMERIC|LC_TIME|LC_COLLATE|LC_MONETARY|LC_PAPER|LC_NAME|LC_ADDRESS|LC_TELEPHONE|LC_MEASUREMENT|LC_IDENTIFICATION)
        export "$_locale_category=$_locale_value" ;;
    esac
  done <<EOF
$(locale_user_settings)
EOF
}

locale_detect() {
  if command -v argvus >/dev/null 2>&1; then
    argvus i18n locale
    return
  fi
  case "$(locale_user_lang)" in
    pt_BR*) printf '%s\n' "pt-BR" ;;
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
  if command -v argvus >/dev/null 2>&1; then
    argvus i18n get "$@"
    return
  fi
  printf '%s\n' "$2"
}
