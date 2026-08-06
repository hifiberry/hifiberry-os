import os
import tempfile
import unittest

from hifiberry_aes67 import configure


class FakeRunner:
    def __init__(self, returncode=0):
        self.calls = []
        self.returncode = returncode

    def __call__(self, cmd, **kwargs):
        self.calls.append(cmd)

        class R:
            pass

        r = R()
        r.returncode = self.returncode
        r.stdout = ""
        r.stderr = ""
        return r

    def restarts(self):
        return [c for c in self.calls if "restart" in c]


class ConfigureTest(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.TemporaryDirectory()
        self.conf = os.path.join(self.dir.name, "conf.d", "60-aes67.conf")
        self.settings = os.path.join(self.dir.name, "settings.json")
        self.model = os.path.join(self.dir.name, "model")
        with open(self.model, "wb") as handle:
            handle.write(b"Raspberry Pi 4 Model B Rev 1.1\x00")

    def tearDown(self):
        self.dir.cleanup()

    def _ensure(self, runner):
        return configure.ensure(runner=runner, conf_path=self.conf,
                                settings_path=self.settings,
                                model_path=self.model)

    def test_first_run_writes_config_and_restarts(self):
        runner = FakeRunner()
        state = self._ensure(runner)
        self.assertTrue(state["changed"])
        self.assertTrue(state["restarted"])
        self.assertEqual(len(runner.restarts()), 1)

    def test_second_run_changes_nothing_and_does_not_restart(self):
        """Restarting PipeWire interrupts playback; it must not happen on every start."""
        self._ensure(FakeRunner())
        runner = FakeRunner()
        state = self._ensure(runner)
        self.assertFalse(state["changed"])
        self.assertFalse(state["restarted"])
        self.assertEqual(runner.restarts(), [])

    def test_board_default_used_when_not_overridden(self):
        state = self._ensure(FakeRunner())
        self.assertEqual(state["latency_msec"], 20)
        self.assertEqual(state["board_default_msec"], 20)
        self.assertFalse(state["overridden"])

    def test_apply_latency_overrides_and_restarts(self):
        self._ensure(FakeRunner())
        runner = FakeRunner()
        state = configure.apply_latency(10, runner=runner, conf_path=self.conf,
                                        settings_path=self.settings,
                                        model_path=self.model)
        self.assertEqual(state["latency_msec"], 10)
        self.assertTrue(state["overridden"])
        self.assertTrue(state["restarted"])
        with open(self.conf) as handle:
            self.assertIn("sess.latency.msec = 10", handle.read())

    def test_apply_none_restores_board_default(self):
        configure.apply_latency(10, runner=FakeRunner(), conf_path=self.conf,
                                settings_path=self.settings, model_path=self.model)
        state = configure.apply_latency(None, runner=FakeRunner(),
                                        conf_path=self.conf,
                                        settings_path=self.settings,
                                        model_path=self.model)
        self.assertEqual(state["latency_msec"], 20)
        self.assertFalse(state["overridden"])

    def test_apply_rejects_out_of_range(self):
        with self.assertRaises(ValueError):
            configure.apply_latency(9999, runner=FakeRunner(), conf_path=self.conf,
                                    settings_path=self.settings,
                                    model_path=self.model)

    def test_failed_restart_is_reported_not_raised(self):
        state = configure.ensure(runner=FakeRunner(returncode=1),
                                 conf_path=self.conf,
                                 settings_path=self.settings,
                                 model_path=self.model)
        self.assertTrue(state["changed"])
        self.assertFalse(state["restarted"])
