import json

from hifiberry_aes67 import pwgraph


class FakeResult:
    def __init__(self, stdout, returncode=0):
        self.stdout = stdout
        self.returncode = returncode
        self.stderr = ""


SAMPLE = [
    {"id": 90, "type": "PipeWire:Interface:Node",
     "info": {"props": {"node.name": "AU-U22-f0f33b : 1", "device.api": "aes67"}}},
    {"id": 12, "type": "PipeWire:Interface:Link", "info": {"props": {}}},
]


def test_dump_parses_json():
    runner = lambda *a, **k: FakeResult(json.dumps(SAMPLE))
    assert pwgraph.dump(runner=runner) == SAMPLE


def test_dump_returns_empty_on_bad_json():
    runner = lambda *a, **k: FakeResult("not json")
    assert pwgraph.dump(runner=runner) == []


def test_dump_returns_empty_when_command_fails():
    runner = lambda *a, **k: FakeResult("", returncode=1)
    assert pwgraph.dump(runner=runner) == []


def test_nodes_filters_by_type():
    assert [n["id"] for n in pwgraph.nodes(SAMPLE)] == [90]


def test_props_reads_nested_props():
    assert pwgraph.props(SAMPLE[0])["device.api"] == "aes67"


def test_props_of_object_without_info_is_empty():
    assert pwgraph.props({"id": 1}) == {}
