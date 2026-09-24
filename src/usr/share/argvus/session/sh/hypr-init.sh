#!/usr/bin/env sh

# shellcheck disable=SC1090,SC1091
ARGVUS_BOOTSTRAP="${ARGVUS_BOOTSTRAP:-${ARGVUS_SYSTEM_CONFIG:-/usr/share/argvus}/session/sh/bootstrap.sh}"
. "$ARGVUS_BOOTSTRAP"

# Appearance owns the live wallpaper helper. Keep session preparation usable
# without that optional component, but load it when the package is present.
ARGVUS_HYPR_HELPER="${ARGVUS_SYSTEM_CONFIG}/appearance/sh/hypr.sh"
[ -r "$ARGVUS_HYPR_HELPER" ] && . "$ARGVUS_HYPR_HELPER"

sessionctl() {
  command -v argvus-sessionctl >/dev/null 2>&1 || return 127
  argvus-sessionctl "$@"
}

start_wallpaper() {
  hypr_apply_wallpaper "$WALLPAPER_PATH"
}

active_theme_name() {
  if [ -f "$ARGVUS_CONFIG_HOME/argvus/.active-theme" ]; then
    sed -n '1p' "$ARGVUS_CONFIG_HOME/argvus/.active-theme"
  else
    printf '%s\n' "$ACTIVE_THEME"
  fi
}

gtk_theme_name_for_theme() {
  case "$1" in
    argvus-light-veil|argvus-light-veil-float|argvus-github-light|argvus-github-light-float|argvus-light-solarized|argvus-light-solarized-float|argvus-light-frost|argvus-light-frost-float|argvus-light-catppuccin-latte|argvus-light-catppuccin-latte-float|argvus-light-gruvbox|argvus-light-gruvbox-float) printf '%s\n' "Adwaita" ;;
    argvus-dark-*|argvus-onedark*|argvus-dark-solitude|argvus-dark-solitude-float) printf '%s\n' "Adwaita-dark" ;;
    *) printf '%s\n' "${GTK_THEME:-Adwaita-dark}" ;;
  esac
}

font_state_value() {
  _key="$1"
  _fallback="$2"
  _fonts_file="${ARGVUS_CONFIG_HOME}/argvus/fonts.conf"

  if [ -f "$_fonts_file" ]; then
    awk -F= -v key="$_key" '
      $1 == key {
        sub(/^[^=]*=/, "")
        gsub(/^[[:space:]]+|[[:space:]]+$/, "")
        print
        found = 1
        exit
      }
      END { exit found ? 0 : 1 }
    ' "$_fonts_file" 2>/dev/null && return 0
  fi

  printf '%s\n' "$_fallback"
}

font_default_value() {
  printf '%s %s\n' \
    "$(font_state_value apps_name "$(font_state_value default_name "IBM Plex Mono")")" \
    "$(font_state_value apps_size "$(font_state_value default_size 12)")"
}

font_monospace_value() {
  printf '%s %s\n' \
    "$(font_state_value terminal_name "$(font_state_value monospace_name "IBM Plex Mono")")" \
    "$(font_state_value terminal_size "$(font_state_value monospace_size 13)")"
}

set_gsettings() {
  _theme="$(active_theme_name)"
  _gtk_theme="$(gtk_theme_name_for_theme "$_theme")"
  _scheme="prefer-dark"
  _default_font="$(font_default_value)"
  _monospace_font="$(font_monospace_value)"
  case "$_theme" in
    argvus-light-veil|argvus-light-veil-float|argvus-github-light|argvus-github-light-float|argvus-light-solarized|argvus-light-solarized-float|argvus-light-frost|argvus-light-frost-float|argvus-light-catppuccin-latte|argvus-light-catppuccin-latte-float|argvus-light-gruvbox|argvus-light-gruvbox-float) _scheme="prefer-light" ;;
  esac

  # GTK Theme
  if command -v gsettings >/dev/null 2>&1; then
    if
      gsettings set org.gnome.desktop.interface icon-theme "Argvus Icons" &&
      gsettings set org.gnome.desktop.interface gtk-theme "$_gtk_theme" &&
      gsettings set org.gnome.desktop.interface color-scheme "$_scheme" &&
      gsettings set org.gnome.desktop.interface font-name "$_default_font" &&
      gsettings set org.gnome.desktop.interface document-font-name "$_default_font" &&
      gsettings set org.gnome.desktop.interface monospace-font-name "$_monospace_font" &&
      gsettings set org.gnome.desktop.interface cursor-theme "${GTK_CURSOR:-Adwaita}"
    then
      argvus_tr session gtk.theme_applied
    else
      argvus_tr session gtk.theme_failed
    fi
  else
    argvus_tr session gtk.gsettings_missing
  fi

  if command -v gsettings >/dev/null 2>&1; then
    # Disabled buttons: minimize,maximize,close.
    if
      gsettings set org.gnome.desktop.wm.preferences button-layout "$BUTTON_LAYOUT"
    then
      argvus_tr session gtk.buttons_disabled
    fi
  fi
}

run_waybars() {
  sessionctl restart waybar
}

sync_rofi_config() {
  _rofi_config="$(paths_config launcher/config/config.rasi)"
  _system_rofi_config="$(paths_system_config launcher/config/config.rasi)"

  if [ ! -f "$_rofi_config" ] && [ -f "$_system_rofi_config" ]; then
    mkdir -p "${_rofi_config%/*}"
    cp "$_system_rofi_config" "$_rofi_config"
  fi

  [ -f "$_rofi_config" ] || return 0

  _rofi_font="$(font_default_value)"
  _font_line="    font: \"$_rofi_font\";"
  if grep -q '^[[:space:]]*font:' "$_rofi_config"; then
    _tmp="${_rofi_config}.tmp.$$"
    awk -v font="$_font_line" '
      /^[[:space:]]*font:/ { print font; next }
      { print }
    ' "$_rofi_config" >"$_tmp" && mv "$_tmp" "$_rofi_config"
    rm -f "$_tmp"
  else
    _tmp="${_rofi_config}.tmp.$$"
    awk -v font="$_font_line" '
      { print }
      /^[[:space:]]*configuration[[:space:]]*{/ { print font }
    ' "$_rofi_config" >"$_tmp" && mv "$_tmp" "$_rofi_config"
    rm -f "$_tmp"
  fi
}

theme_startup_fingerprint() {
  _theme="$1"

  printf 'theme=%s\n' "$_theme"
  for _path in \
    "$(paths_config appearance/sh/theme-switch.sh)" \
    "$(paths_config appearance/sh/accent-switch.sh)" \
    "$(paths_config hyprland/sh/spaces-switch.sh)" \
    "$(paths_system_config session/sh/paths.sh)" \
    "$(paths_system_config "appearance/config/hypr/themes/${_theme}")" \
    "$(paths_system_config "taskbar/config/argvus-taskbar.jsonc")" \
    "$(paths_system_config "taskbar/config/argvus-taskbar.css")" \
    "$(paths_system_config "taskbar/config/themes/${_theme}")" \
    "$(paths_system_config widget-telemetry/config/argvus-widget-telemetry.jsonc)" \
    "$(paths_system_config widget-telemetry/config/argvus-widget-telemetry.css)" \
    "$(paths_system_config "widget-telemetry/config/themes/${_theme}")" \
    "$(paths_system_config launcher/config/config.rasi)" \
    "$(paths_system_config launcher/config/theme.rasi)" \
    "$(paths_system_config "control-panel/config/quickshell/argvus-control-panel/themes/${_theme}")" \
    "$(paths_system_config "launcher/config/themes/${_theme}")" \
    "$(paths_system_config "notifications/config/themes/${_theme}")" \
    "$(paths_system_config "terminal/config/themes/${_theme}")" \
    "$(paths_system_config "system-monitor/config/btop/themes/${_theme}")" \
    "$(paths_system_config "appearance/config/gtk-3.0/themes/${_theme}")" \
    "$(paths_system_config "appearance/config/gtk-4.0/themes/${_theme}")"; do
    if [ -d "$_path" ]; then
      find "$_path" -type f -exec stat -c '%n:%Y:%s' {} \; 2>/dev/null | sort
    elif [ -f "$_path" ]; then
      stat -c '%n:%Y:%s' "$_path" 2>/dev/null || true
    else
      printf '%s:missing\n' "$_path"
    fi
  done
}

theme_startup_materialized() {
  _theme="$1"

  [ -f "$ARGVUS_CONFIG_HOME/argvus/.active-theme" ] || return 1
  for _relative in \
    taskbar/config/argvus-taskbar.jsonc taskbar/config/argvus-taskbar.css \
    "taskbar/config/themes/${_theme}/theme.css" \
    widget-telemetry/config/argvus-widget-telemetry.jsonc \
    widget-telemetry/config/argvus-widget-telemetry.css \
    "widget-telemetry/config/themes/${_theme}/widget-telemetry-theme.css" \
    launcher/config/config.rasi launcher/config/theme.rasi \
    appearance/config/waybar/mode.css; do
    [ ! -f "$(paths_system_config "$_relative")" ] ||
      [ -f "$(paths_user_config "$_relative")" ] || return 1
  done
  [ -f "$(paths_user_config "gtk-4.0/settings.ini")" ] || return 1
  [ -d "$(paths_user_config "quickshell/argvus-control-panel/themes/${_theme}")" ] || return 1
}

apply_startup_theme() {
  _theme="$1"
  _stamp_file="$(paths_cache session/theme-startup.stamp)"
  _fingerprint="$(theme_startup_fingerprint "$_theme")"

  if [ -f "$_stamp_file" ] &&
     [ "$(cat "$_stamp_file" 2>/dev/null || true)" = "$_fingerprint" ] &&
     theme_startup_materialized "$_theme"; then
    return 0
  fi

  if ARGVUS_NO_RUNTIME=1 sh "$(paths_config appearance/sh/theme-switch.sh)" "$_theme" >/dev/null 2>&1; then
    mkdir -p "${_stamp_file%/*}"
    printf '%s' "$_fingerprint" > "$_stamp_file"
  fi
}

apply_display() {
  _mode="$1"
  if command -v argvus-displayctl >/dev/null 2>&1; then
    argvus-displayctl "$_mode"
    return $?
  fi

  case "$_mode" in
    --session-prepare) _legacy_mode="--apply" ;;
    --session-reload) _legacy_mode="--apply-nwg" ;;
    *) _legacy_mode="$_mode" ;;
  esac

  sh "$(paths_config display/sh/monitor-switch.sh)" "$_legacy_mode"
}

should_manage_foot_config() {
  _conf="$1"
  [ -f "$_conf" ] || return 0
  grep -q 'argvus.*/foot/themes' "$_conf"
}

sync_foot_config() {
  _theme="$ACTIVE_THEME"
  if [ -f "$ARGVUS_CONFIG_HOME/argvus/.active-theme" ]; then
    _theme="$(sed -n '1p' "$ARGVUS_CONFIG_HOME/argvus/.active-theme")"
  fi

  _foot_dir="$(paths_user_config foot)"
  _system_foot="$(paths_system_config app-profiles/config/foot)"

  if [ ! -d "$_foot_dir" ] && [ -d "$_system_foot" ]; then
    mkdir -p "$_foot_dir"
    cp -R "$_system_foot/." "$_foot_dir/"
  elif [ -d "$_system_foot" ]; then
    mkdir -p "$_foot_dir"
    if [ -f "$_system_foot/foot.ini" ] && [ ! -e "$_foot_dir/foot.ini" ]; then
      cp "$_system_foot/foot.ini" "$_foot_dir/foot.ini"
    fi
    if [ -d "$_system_foot/themes/${_theme}" ]; then
      mkdir -p "$_foot_dir/themes/${_theme}"
      cp -R "$_system_foot/themes/${_theme}/." "$_foot_dir/themes/${_theme}/"
    fi
  fi

  if [ -f "$_foot_dir/foot.ini" ] && [ -f "$_foot_dir/themes/${_theme}/theme.ini" ]; then
    sed -i "s|^include = .*/foot/themes/.*/theme.ini|include = ${_foot_dir}/themes/${_theme}/theme.ini|" "$_foot_dir/foot.ini"
  fi

  _native_foot="$ARGVUS_CONFIG_HOME/foot/foot.ini"
  if should_manage_foot_config "$_native_foot" && [ -f "$_foot_dir/themes/${_theme}/theme.ini" ]; then
    mkdir -p "${_native_foot%/*}"
    if [ ! -f "$_native_foot" ] && [ -f "$_foot_dir/foot.ini" ]; then
      cp "$_foot_dir/foot.ini" "$_native_foot"
    fi
    sed -i "s|^include = .*/foot/themes/.*/theme.ini|include = ${_foot_dir}/themes/${_theme}/theme.ini|" "$_native_foot"
  fi

  for _pid in $(pgrep -x foot 2>/dev/null) $(pgrep -x footclient 2>/dev/null); do
    kill -USR1 "$_pid" 2>/dev/null || true
  done
}

sync_btop_config() {
  _theme="$ACTIVE_THEME"
  if [ -f "$ARGVUS_CONFIG_HOME/argvus/.active-theme" ]; then
    _theme="$(sed -n '1p' "$ARGVUS_CONFIG_HOME/argvus/.active-theme")"
  fi

  command -v argvus-system-monitor >/dev/null 2>&1 && argvus-system-monitor --apply "$_theme" >/dev/null 2>&1 || true
}

sync_yazi_config() {
  _theme="$ACTIVE_THEME"
  if [ -f "$ARGVUS_CONFIG_HOME/argvus/.active-theme" ]; then
    _theme="$(sed -n '1p' "$ARGVUS_CONFIG_HOME/argvus/.active-theme")"
  fi

  _yazi_dir="$(paths_user_config yazi)"
  _system_yazi="$(paths_system_config app-profiles/config/yazi)"

  if [ ! -d "$_yazi_dir" ] && [ -d "$_system_yazi" ]; then
    mkdir -p "$_yazi_dir"
    cp -R "$_system_yazi/." "$_yazi_dir/"
  elif [ -d "$_system_yazi" ]; then
    mkdir -p "$_yazi_dir"
    for _item in package.toml keymap.toml; do
      if [ -f "$_system_yazi/$_item" ] && [ ! -e "$_yazi_dir/$_item" ]; then
        cp "$_system_yazi/$_item" "$_yazi_dir/$_item"
      fi
    done
    if [ -d "$_system_yazi/flavors" ]; then
      mkdir -p "$_yazi_dir/flavors"
      for _flavor in "$_system_yazi"/flavors/*.yazi; do
        [ -d "$_flavor" ] || continue
        _flavor_dst="$_yazi_dir/flavors/${_flavor##*/}"
        [ -e "$_flavor_dst" ] || cp -R "$_flavor" "$_flavor_dst"
      done
    fi
    if [ -d "$_system_yazi/flavors/${_theme}.yazi" ]; then
      mkdir -p "$_yazi_dir/flavors/${_theme}.yazi"
      cp -R "$_system_yazi/flavors/${_theme}.yazi/." "$_yazi_dir/flavors/${_theme}.yazi/"
    fi
  fi

  if [ -f "$_yazi_dir/flavors/${_theme}.yazi/flavor.toml" ]; then
    printf '[flavor]\ndark = "%s"\n' "$_theme" > "$_yazi_dir/theme.toml"
    export YAZI_CONFIG_HOME="$_yazi_dir"
  elif [ -d "$_system_yazi" ]; then
    export YAZI_CONFIG_HOME="$_system_yazi"
  else
    return 0
  fi

  systemctl --user set-environment YAZI_CONFIG_HOME="$YAZI_CONFIG_HOME" 2>/dev/null || true
  command -v hyprctl >/dev/null 2>&1 && hyprctl setenv "YAZI_CONFIG_HOME,$YAZI_CONFIG_HOME" >/dev/null 2>&1 || true

  _native_yazi="$ARGVUS_CONFIG_HOME/yazi"
  _native_theme="$_native_yazi/theme.toml"
  if [ -f "$_native_theme" ] && grep -q 'argvus-' "$_native_theme" && [ -d "$_yazi_dir/flavors/${_theme}.yazi" ]; then
    mkdir -p "$_native_yazi/flavors/${_theme}.yazi"
    cp -R "$_yazi_dir/flavors/${_theme}.yazi/." "$_native_yazi/flavors/${_theme}.yazi/"
    printf '[flavor]\ndark = "%s"\n' "$_theme" > "$_native_theme"
  fi
}

migrate_monitor_state() {
  _legacy_monitors="$ARGVUS_CONFIG_HOME/hypr/monitors.conf"
  _old_user_lua="$ARGVUS_CONFIG_HOME/argvus/hypr/monitors.lua"
  _generated_lua="$ARGVUS_CONFIG_HOME/argvus/generated/hypr/monitors.lua"

  # Migrate legacy monitors.lua from user override to generated path
  if [ -f "$_old_user_lua" ] && [ ! -f "$_generated_lua" ]; then
    _gen_dir="${_generated_lua%/*}"
    mkdir -p "$_gen_dir"
    mv "$_old_user_lua" "$_generated_lua"
  fi

  # Migrate legacy monitors.conf to ARGVUS state (idempotent)
  if [ -f "$_legacy_monitors" ] && command -v argvus-displayctl >/dev/null 2>&1; then
    _state_file="$ARGVUS_CONFIG_HOME/argvus/.monitors"
    if [ ! -f "$_state_file" ] || [ ! -s "$_state_file" ]; then
      argvus-displayctl --migrate-nwg 2>/dev/null || true
    fi
  fi
}

prepare_session() {
    command -v xdg-user-dirs-update >/dev/null 2>&1 && xdg-user-dirs-update

    migrate_monitor_state

    if [ -f "$ARGVUS_CONFIG_HOME/argvus/.active-theme" ]; then
      _argvus_active_theme="$(sed -n '1p' "$ARGVUS_CONFIG_HOME/argvus/.active-theme")"
      apply_startup_theme "$_argvus_active_theme"
    else
      # First login for this user: apply the packaged default theme so the
      # mutable per-user configs (qt6ct.conf, waybar, rofi, dunst, ...) are
      # lazily materialized from /usr/share/argvus automatically. No
      # argvus --setup --copy-all needed for the DE to be fully themed.
      apply_startup_theme "$ACTIVE_THEME"
    fi
    if [ -f "$ARGVUS_CONFIG_HOME/argvus/.accent-color" ]; then
      sh "$(paths_config appearance/sh/accent-switch.sh)" --startup
    fi
    set_gsettings
    sync_rofi_config
    sync_foot_config
    sync_btop_config
    sync_yazi_config

    # Apply current spacing (mode defaults or Control Panel overrides) before bars start.
    if [ -f "$ARGVUS_CONFIG_HOME/argvus/.active-theme" ] || [ -f "$ARGVUS_CONFIG_HOME/argvus/.spaces" ]; then
      sh "$(paths_config hyprland/sh/spaces-switch.sh)" --apply-static
    fi
    if [ -f "$ARGVUS_CONFIG_HOME/argvus/.active-theme" ] || [ -f "$ARGVUS_CONFIG_HOME/argvus/.borders" ]; then
      sh "$(paths_config hyprland/sh/borders-switch.sh)" --apply-static
    fi

    # Apply saved monitor scale settings (monitor-switch) and any layout
    # written by nwg-displays.
    apply_display --session-prepare 2>/dev/null || true

    # PolicyKit agent and Quickshell inherit these through systemd user env.
    export QT_QPA_PLATFORM=wayland QT_QPA_PLATFORMTHEME=qt6ct QT_QUICK_CONTROLS_STYLE=org.hyprland.style
    sessionctl import-environment >/dev/null 2>&1 || true
}

reload_config() {
    sh "$(paths_config lock/sh/hyprlock-theme.sh)" --invalidate >/dev/null 2>&1 || true
    sync_rofi_config
    sync_foot_config
    sync_btop_config
    sync_yazi_config

    # Apply current spacing before hyprctl reload.
    if [ -f "$ARGVUS_CONFIG_HOME/argvus/.active-theme" ] || [ -f "$ARGVUS_CONFIG_HOME/argvus/.spaces" ]; then
      sh "$(paths_config hyprland/sh/spaces-switch.sh)" --apply-static || return $?
    fi
    if [ -f "$ARGVUS_CONFIG_HOME/argvus/.active-theme" ] || [ -f "$ARGVUS_CONFIG_HOME/argvus/.borders" ]; then
      sh "$(paths_config hyprland/sh/borders-switch.sh)" --apply-static || return $?
    fi

    # Reload Hyprland config (applies gaps from .spaces via hyprland.lua)
    hyprctl reload || return $?

    # Apply monitor layout written by nwg-displays (if changed).
    apply_display --session-reload 2>/dev/null || true
}

case "${1:-}" in
  --started)
    sessionctl ready
  ;;
  --prepare)
    prepare_session
  ;;
  --waybars)
    run_waybars
  ;;
  --set-wallpaper)
    start_wallpaper
  ;;
  --reload-config)
    reload_config
  ;;
  --reload)
    sessionctl reload
  ;;
  *)
    notify-send "$(argvus_tr notifications operation_failed)" \
    "$(argvus_tr session invalid_parameter)"
  ;;
esac
