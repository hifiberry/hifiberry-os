import os
import tempfile
import unittest

from hifiberry_aes67 import settings


class SettingsTest(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.TemporaryDirectory()
        self.path = os.path.join(self.dir.name, "sub", "settings.json")

    def tearDown(self):
        self.dir.cleanup()

    def test_latency_defaults_to_board_default_when_unset(self):
        self.assertEqual(settings.latency_msec(self.path, board_default=20), 20)

    def test_explicit_latency_overrides_board_default(self):
        settings.set_latency(5, self.path)
        self.assertEqual(settings.latency_msec(self.path, board_default=20), 5)

    def test_setting_none_restores_board_default(self):
        settings.set_latency(5, self.path)
        settings.set_latency(None, self.path)
        self.assertEqual(settings.latency_msec(self.path, board_default=20), 20)

    def test_is_overridden_reports_whether_user_chose(self):
        self.assertFalse(settings.is_overridden(self.path))
        settings.set_latency(5, self.path)
        self.assertTrue(settings.is_overridden(self.path))

    def test_corrupt_file_falls_back_to_board_default(self):
        os.makedirs(os.path.dirname(self.path), exist_ok=True)
        with open(self.path, "w") as handle:
            handle.write("{broken")
        self.assertEqual(settings.latency_msec(self.path, board_default=20), 20)

    def test_rejects_out_of_range_values(self):
        with self.assertRaises(ValueError):
            settings.set_latency(0, self.path)
        with self.assertRaises(ValueError):
            settings.set_latency(1000, self.path)

    def test_rejects_non_integer(self):
        with self.assertRaises(ValueError):
            settings.set_latency("nonsense", self.path)
