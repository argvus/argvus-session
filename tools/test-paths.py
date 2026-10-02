#!/usr/bin/env python3
"""Verify mutable/read-only path compatibility without touching a user profile."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
PATHS = ROOT / "src/usr/share/argvus/session/sh/paths.sh"


class PathsTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="argvus-path-test-")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.config = self.base / "config"
        self.system = self.base / "system"
        self.env = os.environ | {"ARGVUS_CONFIG_HOME": str(self.config),
                                 "ARGVUS_SYSTEM_CONFIG": str(self.system)}

    def write(self, path, text="fixture"):
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
        return path

    def resolve(self, relative, mutable=False):
        result = subprocess.run(
            ["sh", "-eu", "-c", '. "$1"; paths_config "$2"', "test", str(PATHS), relative],
            env=self.env | {"ARGVUS_MUTABLE_CONFIG": "1" if mutable else "0"},
            capture_output=True, text=True, check=True)
        return Path(result.stdout.strip())

    def test_override_managed_generated_system_precedence(self):
        rel = "launcher/config/config.rasi"
        expected = self.write(self.system / rel)
        self.assertEqual(self.resolve(rel), expected)
        for sub in ("argvus/data/generated/rofi/config.rasi", "argvus/rofi/config.rasi",
                    "launcher/config/config.rasi", "rofi/config.rasi"):
            expected = self.write(self.config / sub)
            self.assertEqual(self.resolve(rel), expected)

    def test_migrate_power_and_lock_component_copies_without_deleting(self):
        for component, filename in (("power", "hypridle.conf"), ("lock", "hyprlock.conf")):
            rel = f"{component}/config/{filename}"
            source = self.write(self.config / "argvus" / rel, "edited by user")
            self.assertEqual(self.resolve(rel), source)
            target = self.resolve(rel, mutable=True)
            self.assertEqual(target, self.config / "argvus/data/hypr" / filename)
            self.assertEqual(target.read_text(), "edited by user")
            self.assertTrue(source.is_file())
            self.assertEqual(self.resolve(rel), target)

    def test_mutable_paths_do_not_modify_native_override(self):
        rel = "launcher/config/config.rasi"
        override = self.write(self.config / "rofi/config.rasi", "native override")
        self.write(self.system / rel, "packaged")
        self.assertEqual(self.resolve(rel, True).read_text(), "packaged")
        self.assertEqual(self.resolve(rel), override)
        self.assertEqual(override.read_text(), "native override")

    def test_component_generated_edits_are_promoted(self):
        rel = "lock/config/hyprlock.conf"
        source = self.write(self.config / "argvus/data/generated" / rel, "generated edit")
        self.write(self.system / rel, "packaged")
        self.assertEqual(self.resolve(rel), source)
        self.assertEqual(self.resolve(rel, True).read_text(), "generated edit")

    def test_generated_css_shim_uses_packaged_css(self):
        rel = "taskbar/config/argvus-taskbar.css"
        self.write(self.system / rel, "/* complete packaged style */")
        shim = self.write(self.config / "argvus/data/generated/waybar/argvus-taskbar.css",
                          '@import url("/usr/share/argvus/taskbar/config/argvus-taskbar.css");')
        self.assertEqual(self.resolve(rel, True).read_text(), "/* complete packaged style */")
        self.assertTrue(Path(str(shim) + ".retired").is_file())

    def test_get_default_honors_separate_argvus_root(self):
        self.write(self.config / "argvus/data/control-center/defaults.json",
                  '{"terminal":"custom-terminal"}')
        result = subprocess.check_output(
            ["sh", str(PATHS.with_name("get-default.sh")), "terminal"],
            env=self.env | {"XDG_CONFIG_HOME": str(self.base / "native")}, text=True)
        self.assertEqual(result.strip(), "custom-terminal")


if __name__ == "__main__":
    unittest.main()
