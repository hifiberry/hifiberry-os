import unittest

from hifiberry_aes67 import sync


class FakeDb:
    """Stands in for the ConfigDB client."""

    def __init__(self, values=None, writable=True, reachable=True):
        self.values = dict(values or {})
        self.writable = writable
        self.reachable = reachable
        self.writes = []

    def setting_key(self, key):
        return f"player.aes67.{key}"

    def fetch(self, key):
        if not self.reachable:
            return False, None
        return True, self.values.get(key)

    def get(self, key):
        return self.fetch(key)[1]

    def set(self, key, value):
        if not self.writable:
            return False
        self.values[key] = str(value)
        self.writes.append((key, value))
        return True


class SeedTest(unittest.TestCase):
    def test_seeds_board_default_when_unset(self, ):
        db = FakeDb()
        seeded = sync.seed_latency(db=db, model_path=_pi4_model())
        self.assertEqual(seeded, 20)
        self.assertEqual(db.values["player.aes67.latency"], "20")

    def test_does_not_overwrite_a_user_value(self):
        db = FakeDb({"player.aes67.latency": "5"})
        self.assertIsNone(sync.seed_latency(db=db, model_path=_pi4_model()))
        self.assertEqual(db.values["player.aes67.latency"], "5")

    def test_unwritable_configdb_is_not_fatal(self):
        db = FakeDb(writable=False)
        self.assertIsNone(sync.seed_latency(db=db, model_path=_pi4_model()))


class ApplyTest(unittest.TestCase):
    def test_applies_latency_and_stream(self):
        db = FakeDb({"player.aes67.latency": "10",
                     "player.aes67.stream": "AU-U22 : 1"})
        seen = {}
        applied = sync.apply_once(
            db=db,
            apply_latency=lambda v, **kw: seen.setdefault("latency", v),
            set_selection=lambda name: seen.setdefault("stream", name),
        )
        self.assertEqual(seen["latency"], 10)
        self.assertEqual(seen["stream"], "AU-U22 : 1")
        self.assertEqual(applied["latency"], 10)

    def test_unchanged_values_do_not_reapply(self):
        """Applying the latency restarts PipeWire; polling must not do that."""
        db = FakeDb({"player.aes67.latency": "10"})
        calls = []
        state = sync.apply_once(db=db, apply_latency=lambda v, **kw: calls.append(v),
                                set_selection=lambda name: None)
        sync.apply_once(db=db, applied=state,
                        apply_latency=lambda v, **kw: calls.append(v),
                        set_selection=lambda name: None)
        self.assertEqual(calls, [10])

    def test_changed_latency_is_reapplied(self):
        db = FakeDb({"player.aes67.latency": "10"})
        calls = []
        state = sync.apply_once(db=db, apply_latency=lambda v, **kw: calls.append(v),
                                set_selection=lambda name: None)
        db.values["player.aes67.latency"] = "20"
        sync.apply_once(db=db, applied=state,
                        apply_latency=lambda v, **kw: calls.append(v),
                        set_selection=lambda name: None)
        self.assertEqual(calls, [10, 20])

    def test_empty_stream_clears_the_selection(self):
        db = FakeDb({"player.aes67.stream": ""})
        seen = {}
        sync.apply_once(db=db, apply_latency=lambda v, **kw: None,
                        set_selection=lambda name: seen.setdefault("stream", name))
        self.assertIsNone(seen["stream"])

    def test_nonsense_latency_is_ignored(self):
        db = FakeDb({"player.aes67.latency": "soon"})
        calls = []
        sync.apply_once(db=db, apply_latency=lambda v, **kw: calls.append(v),
                        set_selection=lambda name: None)
        self.assertEqual(calls, [])

    def test_out_of_range_latency_does_not_crash_the_loop(self):
        db = FakeDb({"player.aes67.latency": "99999"})

        def rejecting(value, **kwargs):
            raise ValueError("latency must be between 1 and 500 ms")

        applied = sync.apply_once(db=db, apply_latency=rejecting,
                                  set_selection=lambda name: None)
        self.assertNotIn("latency", applied)

    def test_unreachable_configdb_changes_nothing(self):
        """A config-server restart must not look like "the user cleared it"."""
        db = FakeDb({"player.aes67.stream": "AU-U22 : 1"}, reachable=False)
        calls = []
        applied = sync.apply_once(db=db, applied={"stream": "AU-U22 : 1"},
                                  apply_latency=lambda v, **kw: calls.append(v),
                                  set_selection=lambda name: calls.append(name))
        self.assertEqual(calls, [])
        self.assertEqual(applied["stream"], "AU-U22 : 1")

    def test_first_pass_clears_a_stale_local_selection(self):
        """ConfigDB is authoritative: an unset key means nothing is selected."""
        db = FakeDb()
        seen = []
        sync.apply_once(db=db, apply_latency=lambda v, **kw: None,
                        set_selection=lambda name: seen.append(name))
        self.assertEqual(seen, [None])


def _pi4_model():
    import tempfile
    import os
    path = os.path.join(tempfile.mkdtemp(), "model")
    with open(path, "wb") as handle:
        handle.write(b"Raspberry Pi 4 Model B Rev 1.1\x00")
    return path
