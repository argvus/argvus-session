#!/usr/bin/env python3
"""User locale isolation; all writes and mocked commands live in temporary profiles."""
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
LIBRARY = ROOT / "src/usr/share/argvus/session/sh/locale.sh"


class UserLocaleTests(unittest.TestCase):
    def resolve(self, contents=None, generated="en_US.utf8\npt_BR.utf8", legacy=False):
        with tempfile.TemporaryDirectory(prefix="argvus-locale-") as directory:
            base = Path(directory)
            config = base / "custom-config"
            config.mkdir()
            if contents is not None:
                (config / "locale.conf").write_text(contents)
            if legacy:
                (config / "argvus/data/internal").mkdir(parents=True)
                (config / "argvus/data/language").write_text("pt-BR")
                (config / "argvus/data/internal/language").write_text("pt_BR")
            mockbin = base / "bin"
            mockbin.mkdir()
            locale = mockbin / "locale"
            locale.write_text('#!/bin/sh\nprintf "%s\\n" "$TEST_GENERATED_LOCALES"\n')
            locale.chmod(0o755)
            environment = os.environ | {
                "HOME": str(base), "XDG_CONFIG_HOME": str(config),
                "PATH": str(mockbin) + os.pathsep + os.environ["PATH"],
                "TEST_GENERATED_LOCALES": generated,
                "LANG": "pt_BR.UTF-8", "LC_MESSAGES": "pt_BR.UTF-8",
                "LC_ALL": "C.UTF-8", "LANGUAGE": "pt_BR", "LC_TIME": "pt_BR.UTF-8",
            }
            result = subprocess.run([
                "sh", "-c", '. "$1"; locale_apply; printf "%s\\n" "$LANG" "$LC_ALL" "$LC_MESSAGES" "$LANGUAGE" "$LC_TIME"',
                "sh", str(LIBRARY),
            ], env=environment, text=True, capture_output=True, check=True)
            self.assertEqual((config / "locale.conf").exists(), contents is not None)
            return result.stdout.splitlines()

    def test_new_profile_ignores_global_portuguese_and_legacy_files(self):
        for legacy in [False, True]:
            self.assertEqual(self.resolve(legacy=legacy), ["en_US.UTF-8", "", "en_US.UTF-8", "en_US", ""])

    def test_personal_portuguese_and_regional_preferences(self):
        self.assertEqual(self.resolve("# comment\n LANG='pt_BR.UTF-8'\nLC_TIME=en_GB.UTF-8\n"),
                         ["pt_BR.UTF-8", "", "pt_BR.UTF-8", "pt_BR", "en_GB.UTF-8"])

    def test_english_fallback_without_generated_en_us(self):
        self.assertEqual(self.resolve(generated="C.utf8")[:4], ["C.UTF-8", "", "C.UTF-8", "C"])

    def test_empty_invalid_or_missing_lang_uses_english(self):
        for contents in ["", "#LANG=pt_BR.UTF-8\n", "LANG=$(id)\n", "LANG=null\n", "LANG=\n", "LANG=xx_XX.UTF-8\n"]:
            self.assertEqual(self.resolve(contents)[0], "en_US.UTF-8")

    def test_explicit_lang_wins_and_conflicting_message_overrides_are_ignored(self):
        self.assertEqual(self.resolve('LANG="en_US.UTF-8"\nLC_MESSAGES=pt_BR.UTF-8\nLC_ALL=pt_BR.UTF-8\n')[:4],
                         ["en_US.UTF-8", "", "en_US.UTF-8", "en_US"])


if __name__ == "__main__":
    unittest.main()
