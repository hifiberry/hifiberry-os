from unittest.mock import MagicMock

from hifiberry_usbaudio.linker import (
    TARGET_NODE,
    find_node_by_prefix,
    link_pairs,
    list_nodes,
)

PW_CLI_OUTPUT = '''
\tnode.name = "Dummy-Driver"
\tnode.name = "input-processor"
\tnode.name = "alsa_output.platform-soc_107c000000_sound.stereo-fallback"
\tnode.name = "alsa_input.usb-gadget.stereo-fallback"
'''


def _runner(stdout):
    r = MagicMock()
    r.stdout = stdout
    r.returncode = 0
    return MagicMock(return_value=r)


def test_list_nodes_parses_pw_cli_output():
    nodes = list_nodes(runner=_runner(PW_CLI_OUTPUT))
    assert "input-processor" in nodes
    assert TARGET_NODE in nodes


def test_find_node_by_prefix_matches():
    nodes = list_nodes(runner=_runner(PW_CLI_OUTPUT))
    assert find_node_by_prefix("alsa_input.usb-gadget", nodes) == "alsa_input.usb-gadget.stereo-fallback"


def test_find_node_by_prefix_returns_none_when_absent():
    assert find_node_by_prefix("nope", ["a", "b"]) is None


def test_link_pairs_maps_stereo_capture_to_playback():
    pairs = link_pairs("src", "dst")
    assert pairs == [
        ("src:capture_FL", "dst:playback_FL"),
        ("src:capture_FR", "dst:playback_FR"),
    ]


def test_target_is_the_dac_sink_not_the_riaa_preamp():
    """input-processor is /usr/lib/ladspa/riaa.so -- a vinyl EQ curve."""
    assert TARGET_NODE.startswith("alsa_output.")
    assert "input-processor" not in TARGET_NODE
