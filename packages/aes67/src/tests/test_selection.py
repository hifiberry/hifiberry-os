import os
import tempfile
import unittest

from hifiberry_aes67 import selection


class SelectionTest(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.TemporaryDirectory()
        self.path = os.path.join(self.dir.name, "sub", "selection.json")

    def tearDown(self):
        self.dir.cleanup()

    def test_get_returns_none_when_missing(self):
        self.assertIsNone(selection.get(self.path))

    def test_set_then_get_roundtrips(self):
        selection.set("AU-U22-f0f33b : 1", self.path)
        self.assertEqual(selection.get(self.path), "AU-U22-f0f33b : 1")

    def test_set_creates_parent_directory(self):
        selection.set("x", self.path)
        self.assertTrue(os.path.exists(self.path))

    def test_set_none_clears(self):
        selection.set("x", self.path)
        selection.set(None, self.path)
        self.assertIsNone(selection.get(self.path))

    def test_get_returns_none_on_corrupt_file(self):
        os.makedirs(os.path.dirname(self.path), exist_ok=True)
        with open(self.path, "w") as handle:
            handle.write("{not json")
        self.assertIsNone(selection.get(self.path))

    def test_default_path_is_under_user_state(self):
        self.assertIn("hifiberry-aes67", selection.default_path())
