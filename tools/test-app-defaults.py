#!/usr/bin/env python3
"""Verify that `get-default.sh --all` and variables.sh resolve the same default
apps as one `get-default.sh <category>` call per category."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "src/usr/share/argvus/session/sh"
GET_DEFAULT = SCRIPTS / "get-default.sh"
VARIABLES = SCRIPTS / "variables.sh"

CATEGORIES = (
    "terminal file_manager text_editor terminal_editor browser image_viewer "
    "pdf_viewer video_player audio_player archive launcher"
).split()

# variables.sh name of each category it exports.
VARIABLE_OF = {
    "terminal": "TERM",
    "launcher": "FINDER",
    "file_manager": "FILE_MANAGER",
    "terminal_editor": "TERMINAL_EDITOR",
    "text_editor": "TEXT_EDITOR",
    "image_viewer": "IMAGE_VIEWER",
    "pdf_viewer": "PDF_VIEWER",
    "video_player": "VIDEO_PLAYER",
    "audio_player": "AUDIO_PLAYER",
    "archive": "ARCHIVE_APP",
}

STATES = {
    "missing": None,
    "configured": json.dumps({"terminal": "kitty", "browser": "firefox", "file_manager": "spf"}),
    "unusable values": json.dumps({
        "terminal": None, "launcher": "", "file_manager": False, "text_editor": 42,
        "terminal_editor": {"a": 1}, "browser": "\n\nfirefox --new\nsecond\n",
        "image_viewer": "null", "pdf_viewer": ["x"], "video_player": "  mpv  ",
        "audio_player": True, "archive": {},
    }),
    "invalid json": "{not json",
    "not an object": "[1, 2, 3]",
}


class AppDefaultsTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="argvus-defaults-test-")
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.config = self.home / ".config"
        self.env = {
            "HOME": str(self.home),
            "PATH": os.environ["PATH"],
            "ARGVUS_CONFIG_HOME": str(self.config),
            "XDG_STATE_HOME": str(self.home / ".local/state"),
            "ARGVUS_SYSTEM_CONFIG": str(self.home / "system"),
        }

    def write_state(self, content):
        state = self.config / "argvus/data/control-center/defaults.json"
        state.parent.mkdir(parents=True, exist_ok=True)
        if content is None:
            state.unlink(missing_ok=True)
        else:
            state.write_text(content)

    def run_script(self, *arguments):
        return subprocess.run(["sh", str(GET_DEFAULT), *arguments], env=self.env,
                              capture_output=True, text=True, check=True).stdout

    def single(self, category):
        """The first non-empty line of one category, as variables.sh reads it."""
        lines = [line for line in self.run_script(category).split("\n") if line]
        return lines[0] if lines else ""

    def all_categories(self):
        return dict(line.split("\t", 1) for line in self.run_script("--all").splitlines())

    def variables(self):
        names = " ".join(f'"${name}"' for name in VARIABLE_OF.values())
        script = f'BOOTSTRAP_DIR="{SCRIPTS}"; . "{VARIABLES}"; printf "%s\\n" {names}'
        # A TERM from the caller's environment must not leak into the result.
        result = subprocess.run(["sh", "-eu", "-c", script], env=self.env | {"TERM": "xterm"},
                                capture_output=True, text=True, check=True)
        return dict(zip(VARIABLE_OF.values(), result.stdout.splitlines()))

    def test_all_matches_one_call_per_category(self):
        for name, content in STATES.items():
            with self.subTest(state=name):
                self.write_state(content)
                self.assertEqual(self.all_categories(),
                                 {category: self.single(category) for category in CATEGORIES})

    def test_variables_take_the_resolved_defaults(self):
        for name, content in STATES.items():
            with self.subTest(state=name):
                self.write_state(content)
                resolved = self.all_categories()
                expected = {VARIABLE_OF[category]: resolved[category] for category in VARIABLE_OF}
                self.assertEqual(self.variables(), expected)


if __name__ == "__main__":
    unittest.main()
