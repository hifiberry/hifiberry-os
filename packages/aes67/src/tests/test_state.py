import json
import unittest

from hifiberry_aes67 import state

SRC = {"id": 90, "type": "PipeWire:Interface:Node",
       "info": {"props": {"node.name": "S", "device.api": "aes67",
                          "media.class": "Audio/Source"}}}
LINK = {"id": 5, "type": "PipeWire:Interface:Link",
        "info": {"props": {"link.output.node": "S", "link.input.node": "K"}}}


class StateTest(unittest.TestCase):
    def test_playing_when_selected_stream_is_linked(self):
        self.assertEqual(state.current_state([SRC, LINK], "S", "K"), "playing")

    def test_stopped_when_not_linked(self):
        self.assertEqual(state.current_state([SRC], "S", "K"), "stopped")

    def test_stopped_when_nothing_selected(self):
        self.assertEqual(state.current_state([SRC, LINK], None, "K"), "stopped")

    def test_stopped_when_stream_absent(self):
        self.assertEqual(state.current_state([], "S", "K"), "stopped")

    def test_stopped_when_no_sink_resolved(self):
        self.assertEqual(state.current_state([SRC, LINK], "S", None), "stopped")

    def test_post_state_sends_expected_payload(self):
        captured = {}

        def opener(request, timeout=0):
            captured["url"] = request.full_url
            captured["body"] = json.loads(request.data.decode())

            class R:
                def __enter__(self_inner):
                    return self_inner

                def __exit__(self_inner, *a):
                    return False

            return R()

        self.assertTrue(state.post_state("playing", port=1080, opener=opener))
        self.assertEqual(captured["url"],
                         "http://localhost:1080/api/player/aes67/update")
        self.assertEqual(captured["body"],
                         {"type": "state_changed", "state": "playing"})

    def test_post_state_returns_false_on_error(self):
        def opener(request, timeout=0):
            raise OSError("connection refused")

        self.assertFalse(state.post_state("playing", port=1080, opener=opener))
