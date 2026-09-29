#!/usr/bin/env python3
"""Exercise the central reload without reaching the live user service manager."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ReloadTests(unittest.TestCase):
    def test_theme_transaction_runs_runtime_reload_without_recursive_projection(self):
        with tempfile.TemporaryDirectory() as directory:
            base = Path(directory)
            mockbin = base / "bin"
            mockbin.mkdir()
            systemctl = mockbin / "systemctl"
            systemctl.write_text(
                '#!/bin/sh\n'
                'printf "%s\\n" "$*" >> "$TEST_LOG"\n')
            systemctl.chmod(0o755)
            system = base / "system"
            scripts = system / "session/sh"
            scripts.mkdir(parents=True)
            marker = base / "projection-ran"
            (scripts / "hypr-init.sh").write_text(
                f'printf touched > "{marker}"\nexit 0\n')
            (scripts / "bootstrap.sh").write_text(
                'paths_cache() { printf "%s/%s\\n" "$XDG_CACHE_HOME" "$1"; }\n')
            log = base / "commands.log"
            result = subprocess.run(
                ["sh", str(ROOT / "src/usr/bin/argvus-sessionctl"), "reload"],
                env=os.environ | {
                    "PATH": str(mockbin) + os.pathsep + os.environ["PATH"],
                    "ARGVUS_SYSTEM_CONFIG": str(system),
                    "ARGVUS_CONFIG_HOME": str(base / "config"),
                    "XDG_CACHE_HOME": str(base / "cache"),
                    "XDG_STATE_HOME": str(base / "state"),
                    "ARGVUS_THEME_SWITCH": "1",
                    "TEST_LOG": str(log),
                }, capture_output=True, text=True, timeout=10)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertTrue(marker.exists())
            self.assertIn("--user restart", log.read_text())

    def test_components_restart_after_success_failed_or_missing_config_sync(self):
        for status in (0, 42, None):
            with self.subTest(config_status=status), tempfile.TemporaryDirectory() as directory:
                base = Path(directory)
                mockbin = base / "bin"
                mockbin.mkdir()
                for name in ("systemctl", "dbus-update-activation-environment"):
                    command = mockbin / name
                    command.write_text('#!/bin/sh\nprintf "%s\\n" "$*" >> "$TEST_LOG"\n')
                    command.chmod(0o755)
                system = base / "system"
                scripts = system / "session/sh"
                scripts.mkdir(parents=True)
                (scripts / "bootstrap.sh").write_text(
                    'paths_cache() { printf "%s/%s\\n" "$XDG_CACHE_HOME" "$1"; }\n')
                if status is not None:
                    (scripts / "hypr-init.sh").write_text(f"exit {status}\n")
                log = base / "commands.log"
                state = base / "cache/waybar/widget-telemetry-state"
                state.parent.mkdir(parents=True)
                state.write_text("enabled\n")
                result = subprocess.run(
                    ["sh", str(ROOT / "src/usr/bin/argvus-sessionctl"), "reload"],
                    env=os.environ | {
                        "PATH": str(mockbin) + os.pathsep + os.environ["PATH"],
                        "ARGVUS_SYSTEM_CONFIG": str(system),
                        "ARGVUS_CONFIG_HOME": str(base / "config"),
                        "XDG_CACHE_HOME": str(base / "cache"),
                        "XDG_STATE_HOME": str(base / "state"),
                        "TEST_LOG": str(log),
                    }, capture_output=True, text=True, timeout=10)
                self.assertEqual(result.returncode, 78 if status is None else status, result.stderr)
                restarts = [line for line in log.read_text().splitlines()
                            if line.startswith("--user restart ")]
                self.assertEqual(len(restarts), 1)
                for component in ("wallpaper", "hypridle", "taskbar", "widget-telemetry",
                                  "dunst", "control-panel", "snappy-switcher", "polkit"):
                    self.assertIn(f"argvus-{component}.service", restarts[0])


if __name__ == "__main__":
    unittest.main()
