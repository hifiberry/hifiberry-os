from hifiberry_aes67 import registry

AES67_NODE = {
    "id": 90, "type": "PipeWire:Interface:Node",
    "info": {"props": {
        "node.name": "AU-U22-f0f33b : 1",
        "device.api": "aes67",
        "media.class": "Audio/Source",
        "rtp.destination.ip": "239.69.55.186",
        "rtp.destination.port": 5004,
        "rtp.channels": 2,
        "rtp.rate": 48000,
        "rtp.mime": "L24",
        "rtp.origin": "- 758697 758697 IN IP4 192.168.1.157",
    }},
}
DAC_NODE = {
    "id": 77, "type": "PipeWire:Interface:Node",
    "info": {"props": {"node.name": "alsa_output.x", "media.class": "Audio/Sink"}},
}
# An AES67 *sink* must not be listed: this package is receive-only.
AES67_SINK = {
    "id": 91, "type": "PipeWire:Interface:Node",
    "info": {"props": {"node.name": "rtp-sink", "device.api": "aes67",
                       "media.class": "Audio/Sink"}},
}


def test_streams_extracts_aes67_sources():
    got = registry.streams([AES67_NODE, DAC_NODE, AES67_SINK])
    assert len(got) == 1
    s = got[0]
    assert s["name"] == "AU-U22-f0f33b : 1"
    assert s["channels"] == 2
    assert s["rate"] == 48000
    assert s["format"] == "L24"
    assert s["address"] == "239.69.55.186"
    assert s["port"] == 5004
    assert s["node_id"] == 90


def test_source_ip_parsed_from_rtp_origin():
    assert registry.streams([AES67_NODE])[0]["source_ip"] == "192.168.1.157"


def test_source_ip_none_when_origin_malformed():
    node = {"id": 1, "type": "PipeWire:Interface:Node",
            "info": {"props": {"device.api": "aes67", "media.class": "Audio/Source",
                               "node.name": "x", "rtp.origin": "garbage"}}}
    assert registry.streams([node])[0]["source_ip"] is None


def test_streams_empty_when_no_aes67():
    assert registry.streams([DAC_NODE]) == []


def test_find_matches_by_name():
    assert registry.find([AES67_NODE], "AU-U22-f0f33b : 1")["node_id"] == 90


def test_find_returns_none_for_unknown():
    assert registry.find([AES67_NODE], "nope") is None
