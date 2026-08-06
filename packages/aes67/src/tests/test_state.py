import json
import unittest

from hifiberry_aes67 import state

SRC = {"id": 90, "type": "PipeWire:Interface:Node",
       "info": {"props": {"node.name": "S", "device.api": "aes67",
                          "media.class": "Audio/Source"}}}
# Links reference nodes by numeric id, so the sink must exist as a node.
SINK = {"id": 99, "type": "PipeWire:Interface:Node",
        "info": {"props": {"node.name": "K", "media.class": "Audio/Sink"}}}
LINK = {"id": 5, "type": "PipeWire:Interface:Link",
        "info": {"props": {"link.output.node": 90, "link.input.node": 99}}}


class StateTest(unittest.TestCase):
    def test_playing_when_selected_stream_is_linked(self):
        self.assertEqual(state.current_state([SRC, SINK, LINK], "S", "K"), "playing")

    def test_stopped_when_not_linked(self):
        self.assertEqual(state.current_state([SRC], "S", "K"), "stopped")

    def test_stopped_when_nothing_selected(self):
        self.assertEqual(state.current_state([SRC, SINK, LINK], None, "K"), "stopped")

    def test_stopped_when_stream_absent(self):
        self.assertEqual(state.current_state([], "S", "K"), "stopped")

    def test_stopped_when_no_sink_resolved(self):
        self.assertEqual(state.current_state([SRC, SINK, LINK], "S", None), "stopped")

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


class RunTest(unittest.TestCase):
    """The reporter must survive an audiocontrol restart."""

    def _runner_returning(self, objects):
        import json as _json

        def runner(cmd, **kwargs):
            class R:
                returncode = 0
                stderr = ""
                stdout = ""
            r = R()
            if cmd[0] == "pw-dump":
                r.stdout = _json.dumps(objects)
            elif cmd[0] == "pw-metadata":
                r.stdout = ("update: id:0 key:'default.audio.sink' "
                            "value:'{\"name\":\"K\"}' type:''\n")
            return r
        return runner

    def test_resyncs_periodically_without_a_transition(self):
        posts = []
        original = state.post_state
        state.post_state = lambda s, port=0, opener=None: posts.append(s) or True
        try:
            state.run(interval=0, runner=self._runner_returning([SRC, SINK, LINK]),
                      path="/nonexistent", iterations=5, resync_after=2)
        finally:
            state.post_state = original
        # One post for the initial state, plus resyncs -- not a single post.
        self.assertGreater(len(posts), 1)

    def test_failed_post_is_retried_next_poll(self):
        attempts = []
        original = state.post_state

        def failing(s, port=0, opener=None):
            attempts.append(s)
            return False

        state.post_state = failing
        try:
            state.run(interval=0, runner=self._runner_returning([SRC, SINK, LINK]),
                      path="/nonexistent", iterations=3, resync_after=99)
        finally:
            state.post_state = original
        self.assertEqual(len(attempts), 3)
