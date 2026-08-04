from hifiberry_aes67 import sink

METADATA_OUTPUT = (
    "update: id:0 key:'default.audio.sink' "
    "value:'{\"name\":\"speakereq2x2\"}' type:'Spa:String:JSON'\n"
)

SPEAKEREQ = {"id": 38, "type": "PipeWire:Interface:Node",
             "info": {"props": {"node.name": "speakereq2x2", "media.class": "Audio/Sink"}}}
ALSA = {"id": 77, "type": "PipeWire:Interface:Node",
        "info": {"props": {"node.name": "alsa_output.platform-soc.iec958-stereo",
                           "media.class": "Audio/Sink"}}}
RIAA = {"id": 36, "type": "PipeWire:Interface:Node",
        "info": {"props": {"node.name": "input-processor", "media.class": "Audio/Sink"}}}


class FakeResult:
    def __init__(self, stdout, returncode=0):
        self.stdout, self.returncode, self.stderr = stdout, returncode, ""


def test_uses_default_audio_sink_from_metadata():
    runner = lambda *a, **k: FakeResult(METADATA_OUTPUT)
    assert sink.default_sink([SPEAKEREQ, ALSA], runner=runner) == "speakereq2x2"


def test_falls_back_to_alsa_output_when_metadata_empty():
    runner = lambda *a, **k: FakeResult("")
    assert sink.default_sink([ALSA], runner=runner) == "alsa_output.platform-soc.iec958-stereo"


def test_never_returns_input_processor():
    """input-processor is the RIAA phono curve; routing AES67 through it is a bug."""
    runner = lambda *a, **k: FakeResult(
        "update: id:0 key:'default.audio.sink' value:'{\"name\":\"input-processor\"}' type:''\n"
    )
    assert sink.default_sink([RIAA, ALSA], runner=runner) != "input-processor"


def test_returns_none_when_no_sink_exists():
    runner = lambda *a, **k: FakeResult("")
    assert sink.default_sink([RIAA], runner=runner) is None


def test_metadata_name_not_in_graph_falls_back():
    runner = lambda *a, **k: FakeResult(
        "update: id:0 key:'default.audio.sink' value:'{\"name\":\"ghost\"}' type:''\n"
    )
    assert sink.default_sink([ALSA], runner=runner) == "alsa_output.platform-soc.iec958-stereo"
