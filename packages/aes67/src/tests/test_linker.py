import json
import unittest

from hifiberry_aes67 import linker

AES67 = {"id": 90, "type": "PipeWire:Interface:Node",
         "info": {"props": {"node.name": "AU-U22 : 1", "device.api": "aes67",
                            "media.class": "Audio/Source"}}}
SINK = {"id": 38, "type": "PipeWire:Interface:Node",
        "info": {"props": {"node.name": "speakereq2x2", "media.class": "Audio/Sink"}}}
GRAPH = [AES67, SINK]
LINKED = GRAPH + [{"id": 5, "type": "PipeWire:Interface:Link",
                   "info": {"props": {"link.output.node": "AU-U22 : 1",
                                      "link.input.node": "speakereq2x2"}}}]


class FakeRunner:
    def __init__(self, dump_payload, link_rc=0, link_stderr=""):
        self.dump_payload = dump_payload
        self.link_rc = link_rc
        self.link_stderr = link_stderr
        self.calls = []

    def __call__(self, cmd, **kwargs):
        self.calls.append(cmd)

        class R:
            pass

        r = R()
        r.returncode = 0
        r.stderr = ""
        r.stdout = ""
        if cmd[0] == "pw-dump":
            r.stdout = json.dumps(self.dump_payload)
        elif cmd[0] == "pw-metadata":
            r.stdout = ("update: id:0 key:'default.audio.sink' "
                        "value:'{\"name\":\"speakereq2x2\"}' type:''\n")
        elif cmd[0] == "pw-link":
            r.returncode = self.link_rc
            r.stderr = self.link_stderr
        return r

    def link_calls(self):
        return [c for c in self.calls if c[0] == "pw-link"]


class LinkerTest(unittest.TestCase):
    def test_connect_links_selected_stream_to_default_sink(self):
        runner = FakeRunner(GRAPH)
        self.assertEqual(linker.connect(runner=runner, selected="AU-U22 : 1"), 0)
        self.assertIn(["pw-link", "AU-U22 : 1", "speakereq2x2"], runner.calls)

    def test_connect_without_selection_is_a_noop_success(self):
        runner = FakeRunner(GRAPH)
        self.assertEqual(linker.connect(runner=runner, selected=None), 0)
        self.assertEqual(runner.link_calls(), [])

    def test_connect_fails_when_stream_absent(self):
        runner = FakeRunner([SINK])
        self.assertEqual(linker.connect(runner=runner, selected="ghost"), 1)

    def test_connect_fails_when_no_sink(self):
        runner = FakeRunner([AES67])
        self.assertEqual(linker.connect(runner=runner, selected="AU-U22 : 1"), 1)

    def test_existing_link_is_not_an_error(self):
        runner = FakeRunner(GRAPH, link_rc=1, link_stderr="failed to link: File exists")
        self.assertEqual(linker.connect(runner=runner, selected="AU-U22 : 1"), 0)

    def test_disconnect_issues_delete(self):
        runner = FakeRunner(GRAPH)
        linker.disconnect(runner=runner, selected="AU-U22 : 1")
        self.assertIn(["pw-link", "-d", "AU-U22 : 1", "speakereq2x2"], runner.calls)

    def test_disconnect_without_selection_succeeds(self):
        runner = FakeRunner(GRAPH)
        self.assertEqual(linker.disconnect(runner=runner, selected=None), 0)

    def test_is_linked_detects_existing_link(self):
        self.assertTrue(linker.is_linked(LINKED, "AU-U22 : 1", "speakereq2x2"))
        self.assertFalse(linker.is_linked(GRAPH, "AU-U22 : 1", "speakereq2x2"))

    def test_watch_links_when_stream_present_but_unlinked(self):
        """A transmitter that returns after a power-cycle must get relinked."""
        runner = FakeRunner(GRAPH)
        linker.watch(interval=0, runner=runner, selected="AU-U22 : 1", iterations=1)
        self.assertIn(["pw-link", "AU-U22 : 1", "speakereq2x2"], runner.calls)

    def test_watch_is_quiet_while_stream_absent(self):
        runner = FakeRunner([SINK])
        linker.watch(interval=0, runner=runner, selected="AU-U22 : 1", iterations=1)
        self.assertEqual(runner.link_calls(), [])

    def test_watch_does_not_relink_when_already_linked(self):
        runner = FakeRunner(LINKED)
        linker.watch(interval=0, runner=runner, selected="AU-U22 : 1", iterations=1)
        self.assertEqual(runner.link_calls(), [])
