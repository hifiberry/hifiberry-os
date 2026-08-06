import os
import tempfile
import unittest

from hifiberry_aes67 import pwconf


class PwconfTest(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.TemporaryDirectory()
        self.path = os.path.join(self.dir.name, "pipewire.conf.d", "60-aes67.conf")

    def tearDown(self):
        self.dir.cleanup()

    def test_render_contains_latency_and_interface(self):
        text = pwconf.render(latency_msec=20, interface="eth0")
        self.assertIn("sess.latency.msec = 20", text)
        self.assertIn("local.ifname = eth0", text)

    def test_render_declares_exactly_one_rtp_sap_module(self):
        """A second module instance would be loaded, not merged -- never emit two."""
        text = pwconf.render(latency_msec=3, interface="eth0")
        self.assertEqual(text.count("libpipewire-module-rtp-sap"), 1)

    def test_write_creates_file_and_reports_change(self):
        self.assertTrue(pwconf.write(self.path, latency_msec=20, interface="eth0"))
        self.assertTrue(os.path.exists(self.path))

    def test_write_is_idempotent(self):
        pwconf.write(self.path, latency_msec=20, interface="eth0")
        self.assertFalse(pwconf.write(self.path, latency_msec=20, interface="eth0"))

    def test_write_reports_change_when_latency_differs(self):
        pwconf.write(self.path, latency_msec=20, interface="eth0")
        self.assertTrue(pwconf.write(self.path, latency_msec=10, interface="eth0"))

    def test_default_path_is_under_user_pipewire_config(self):
        self.assertIn("pipewire.conf.d", pwconf.default_path())
