import unittest

from hifiberry_aes67 import api

SRC = {"id": 90, "type": "PipeWire:Interface:Node",
       "info": {"props": {"node.name": "S", "device.api": "aes67",
                          "media.class": "Audio/Source", "rtp.channels": 2,
                          "rtp.rate": 48000, "rtp.mime": "L24",
                          "rtp.destination.ip": "239.69.55.186",
                          "rtp.destination.port": 5004}}}
# Links reference nodes by numeric id, so the sink must exist as a node.
SINK = {"id": 99, "type": "PipeWire:Interface:Node",
        "info": {"props": {"node.name": "K", "media.class": "Audio/Sink"}}}
LINK = {"id": 5, "type": "PipeWire:Interface:Link",
        "info": {"props": {"link.output.node": 90, "link.input.node": 99}}}


class ApiTest(unittest.TestCase):
    def test_streams_endpoint_lists_discovered(self):
        code, body = api.handle_get("/api/v1/streams", [SRC], None, "K")
        self.assertEqual(code, 200)
        self.assertEqual(len(body["streams"]), 1)
        self.assertEqual(body["streams"][0]["name"], "S")

    def test_selection_endpoint_reports_current(self):
        code, body = api.handle_get("/api/v1/selection", [SRC], "S", "K")
        self.assertEqual(code, 200)
        self.assertEqual(body["stream"], "S")

    def test_status_reports_receiving_when_linked(self):
        code, body = api.handle_get("/api/v1/status", [SRC, SINK, LINK], "S", "K")
        self.assertEqual(code, 200)
        self.assertTrue(body["receiving"])
        self.assertEqual(body["sink"], "K")

    def test_status_not_receiving_when_unlinked(self):
        _, body = api.handle_get("/api/v1/status", [SRC], "S", "K")
        self.assertFalse(body["receiving"])

    def test_unknown_path_is_404(self):
        code, _ = api.handle_get("/api/v1/nope", [SRC], None, "K")
        self.assertEqual(code, 404)

    def test_post_selection_accepts_known_stream(self):
        written = {}
        code, body = api.handle_post("/api/v1/selection", {"stream": "S"}, [SRC],
                                     setter=lambda name: written.setdefault("n", name))
        self.assertEqual(code, 200)
        self.assertEqual(written["n"], "S")
        self.assertEqual(body["stream"], "S")

    def test_post_selection_accepts_null_to_unroute(self):
        written = {}
        code, _ = api.handle_post("/api/v1/selection", {"stream": None}, [SRC],
                                  setter=lambda name: written.setdefault("n", name))
        self.assertEqual(code, 200)
        self.assertIsNone(written["n"])

    def test_post_selection_rejects_unknown_stream(self):
        code, body = api.handle_post("/api/v1/selection", {"stream": "ghost"}, [SRC],
                                     setter=lambda name: None)
        self.assertEqual(code, 400)
        self.assertIn("error", body)

    def test_post_to_unknown_path_is_404(self):
        code, _ = api.handle_post("/api/v1/nope", {}, [SRC], setter=lambda n: None)
        self.assertEqual(code, 404)


class SettingsApiTest(unittest.TestCase):
    def test_get_settings_reports_bounds_and_board_default(self):
        code, body = api.handle_get_settings(20, 20, False, "eth0")
        self.assertEqual(code, 200)
        self.assertEqual(body["latency_msec"], 20)
        self.assertEqual(body["board_default_msec"], 20)
        self.assertFalse(body["overridden"])
        self.assertEqual(body["interface"], "eth0")
        self.assertIn("min_msec", body)
        self.assertIn("max_msec", body)

    def test_post_settings_applies_integer(self):
        seen = {}
        code, body = api.handle_post_settings(
            {"latency_msec": 10},
            apply_latency=lambda v: seen.setdefault("v", v) or {"latency_msec": v})
        self.assertEqual(code, 200)
        self.assertEqual(seen["v"], 10)

    def test_post_settings_accepts_null_for_board_default(self):
        seen = {}
        code, _ = api.handle_post_settings(
            {"latency_msec": None},
            apply_latency=lambda v: seen.setdefault("v", v) or {"latency_msec": 20})
        self.assertEqual(code, 200)
        self.assertIsNone(seen["v"])

    def test_post_settings_rejects_non_integer(self):
        code, body = api.handle_post_settings(
            {"latency_msec": "fast"}, apply_latency=lambda v: {})
        self.assertEqual(code, 400)
        self.assertIn("error", body)

    def test_post_settings_rejects_boolean(self):
        code, _ = api.handle_post_settings(
            {"latency_msec": True}, apply_latency=lambda v: {})
        self.assertEqual(code, 400)

    def test_post_settings_surfaces_range_error(self):
        def apply_latency(v):
            raise ValueError("latency must be between 1 and 500 ms")

        code, body = api.handle_post_settings({"latency_msec": 9999},
                                              apply_latency=apply_latency)
        self.assertEqual(code, 400)
        self.assertIn("between", body["error"])
