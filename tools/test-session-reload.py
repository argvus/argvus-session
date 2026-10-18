#!/usr/bin/env python3
"""Exercise the session reload flow without reaching the live session.

The reload decisions, unit tables and the compositor calls live in
argvus-config and are covered by its Rust tests. These tests check the part
that stays in argvus-sessionctl: which argvus-config command it runs, with
which arguments, and how it reports the result.

Every test isolates the environment: a mock bin directory replaces the
private commands, a mock systemctl and hyprctl record calls, and the
Hyprland and Wayland variables are removed so nothing reaches the real
compositor or the user manager.
"""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
ISOLATED_VARIABLES = ("HYPRLAND_INSTANCE_SIGNATURE", "WAYLAND_DISPLAY", "DISPLAY")

# Mock argvus-config. It records every call, answers the plan from STUB_PLAN,
# and writes the marker for the commands that changed state.
MOCK_CONFIG = """#!/bin/sh
case "$1" in
  session-prepare) printf prepared > "$TEST_MARKER" ;;
  session-reload-config)
    printf reload > "$TEST_MARKER"
    printf 'argvus-config %s\\n' "$*" >> "$TEST_LOG"
    exit "${STUB_RELOAD_STATUS:-0}" ;;
  session-plan) printf '%b' "${STUB_PLAN:-plan\\nfull\\n}"; exit 0 ;;
  session-telemetry) printf 'disabled\\n'; exit 0 ;;
esac
printf 'argvus-config %s\\n' "$*" >> "$TEST_LOG"
exit 0
"""


def write_executable(path, text):
    path.write_text(text)
    path.chmod(0o755)


def mock_bin(base):
    """A bin directory with the mocks every test needs."""
    mockbin = base / "bin"
    mockbin.mkdir()
    write_executable(mockbin / "dbus-update-activation-environment", "#!/bin/sh\nexit 0\n")
    write_executable(
        mockbin / "systemctl",
        '#!/bin/sh\n'
        'if [ "$1" = "--user" ] && [ "$2" = "show-environment" ]; then exit 0; fi\n'
        'printf "%s\\n" "$*" >> "$TEST_LOG"\n')
    # A hyprctl that is never the compositor's: it only records the call.
    write_executable(mockbin / "hyprctl", '#!/bin/sh\nprintf "hyprctl %s\\n" "$*" >> "$TEST_LOG"\n')
    write_executable(mockbin / "argvus-config", MOCK_CONFIG)
    return mockbin


def isolated_env(mockbin, base, **extra):
    """The environment of a sessionctl run, with the session variables removed."""
    env = {key: value for key, value in os.environ.items() if key not in ISOLATED_VARIABLES}
    env |= {
        "PATH": str(mockbin) + os.pathsep + os.environ["PATH"],
        "ARGVUS_COMMANDS_DIR": str(mockbin),
        "ARGVUS_CONFIG_HOME": str(base / "config"),
        "XDG_CACHE_HOME": str(base / "cache"),
        "XDG_STATE_HOME": str(base / "state"),
        "XDG_RUNTIME_DIR": str(base / "run"),
        "TEST_LOG": str(base / "commands.log"),
    }
    env.update(extra)
    return env


def run_sessionctl(env, *arguments):
    return subprocess.run(
        ["sh", str(ROOT / "src/usr/bin/argvus-sessionctl"), *arguments],
        env=env, capture_output=True, text=True, timeout=10)


def read_log(base):
    log = base / "commands.log"
    return log.read_text().splitlines() if log.exists() else []


class SessionctlDelegationTests(unittest.TestCase):
    def test_prepare_runs_the_session_preparation_in_argvus_config(self):
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            mockbin = mock_bin(base)
            marker = base / "prepared"
            env = isolated_env(mockbin, base, TEST_MARKER=str(marker))
            result = run_sessionctl(env, "prepare")
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(marker.read_text(), "prepared")
            self.assertNotIn("start --wait argvus-config.service", "\n".join(read_log(base)))

    def test_reload_delegates_to_config_service_without_nested_projection(self):
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            mockbin = mock_bin(base)
            marker = base / "reloaded"
            env = isolated_env(mockbin, base, ARGVUS_THEME_SWITCH="1", TEST_MARKER=str(marker))
            result = run_sessionctl(env, "reload")
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn("--user reload-or-restart argvus-config.service",
                          "\n".join(read_log(base)))
            self.assertFalse(marker.exists(), "the projection must not run from the reload")

    def test_reload_desktop_runs_the_runtime_reload_only(self):
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            mockbin = mock_bin(base)
            marker = base / "reloaded"
            env = isolated_env(mockbin, base, TEST_MARKER=str(marker))
            result = run_sessionctl(env, "reload-desktop")
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(marker.read_text(), "reload")
            self.assertIn("argvus-config session-reload-config", read_log(base))
            self.assertNotIn("--user restart argvus-taskbar.service", read_log(base))

    def test_full_reload_restarts_components_only_after_a_successful_reload(self):
        for status in (0, 42, None):
            with self.subTest(reload_status=status), tempfile.TemporaryDirectory() as directory:
                base = Path(directory)
                mockbin = mock_bin(base)
                marker = base / "reloaded"
                # 127 is what a missing command returns; it is the failure case.
                reload_status = 127 if status is None else status
                env = isolated_env(mockbin, base, TEST_MARKER=str(marker),
                                   STUB_RELOAD_STATUS=str(reload_status),
                                   STUB_PLAN="plan\\nfull\\n")
                result = run_sessionctl(env, "apply-config-runtime")
                expected = reload_status
                self.assertEqual(result.returncode, expected, result.stderr)
                calls = read_log(base)
                restarts = [line for line in calls if line.startswith("argvus-config session-restart")]
                if status == 0:
                    self.assertEqual(restarts, [
                        "argvus-config session-restart wallpaper hypridle waybar dunst "
                        "control-panel snappy-switcher polkit"])
                else:
                    self.assertEqual(restarts, [])

    def test_targeted_power_reload_restarts_only_hypridle(self):
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            mockbin = mock_bin(base)
            env = isolated_env(mockbin, base, STUB_PLAN="targets\\nhypridle\\n")
            result = run_sessionctl(env, "apply-config-runtime")
            self.assertEqual(result.returncode, 0, result.stderr)
            calls = read_log(base)
            self.assertIn("argvus-config session-restart hypridle", calls)
            self.assertEqual([line for line in calls if " restart " in line
                              and line.startswith("--user")], [])


if __name__ == "__main__":
    unittest.main()
