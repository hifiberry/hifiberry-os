from unittest.mock import MagicMock, patch

from hifiberry_usbaudio.linker import (
    GADGET_NODE_PREFIX,
    TARGET_NODE,
    connect,
    disconnect,
    find_node_by_prefix,
    find_node_exact,
    link_pairs,
    list_nodes,
)

# Real `pw-cli ls Node` output captured on a CM5 with the UAC2 gadget bound
# (/sys/class/udc/ == "1000480000.usb"). Includes both the gadget's own
# capture node and the DAC2 ADC Pro's own ADC capture node
# (alsa_input.platform-soc_107c000000_sound.stereo-fallback) -- the two must
# never be confused, since routing the DAC's own ADC into the DAC's own sink
# would be a feedback loop, not USB audio.
PW_CLI_OUTPUT = '''
\tnode.name = "Dummy-Driver"
\tnode.name = "input-processor"
\tnode.name = "speakereq2x2"
\tnode.name = "alsa_output.platform-1000480000.usb.stereo-fallback"
\tnode.name = "alsa_input.platform-1000480000.usb.stereo-fallback"
\tnode.name = "alsa_output.platform-soc_107c000000_sound.stereo-fallback"
\tnode.name = "alsa_input.platform-soc_107c000000_sound.stereo-fallback"
'''


def _runner(stdout):
    r = MagicMock()
    r.stdout = stdout
    r.returncode = 0
    return MagicMock(return_value=r)


def _connect_runner():
    """A runner that answers pw-cli ls Node with PW_CLI_OUTPUT and
    succeeds (returncode 0) for any pw-link call, recording every
    invocation."""
    ls_result = MagicMock(stdout=PW_CLI_OUTPUT, returncode=0, stderr="")
    link_result = MagicMock(stdout="", returncode=0, stderr="")

    def _run(cmd, **kwargs):
        if cmd[:2] == ["pw-cli", "ls"]:
            return ls_result
        return link_result

    return MagicMock(side_effect=_run)


def test_list_nodes_parses_pw_cli_output():
    nodes = list_nodes(runner=_runner(PW_CLI_OUTPUT))
    assert "input-processor" in nodes
    assert TARGET_NODE in nodes


def test_find_node_by_prefix_matches():
    nodes = list_nodes(runner=_runner(PW_CLI_OUTPUT))
    assert (
        find_node_by_prefix(GADGET_NODE_PREFIX, nodes)
        == "alsa_input.platform-1000480000.usb.stereo-fallback"
    )


def test_gadget_node_prefix_selects_the_gadget_not_the_dacs_own_adc():
    """The DAC2 ADC Pro's own ADC capture node
    (alsa_input.platform-soc_107c000000_sound.stereo-fallback) is present
    in the same node list as the gadget's capture node. GADGET_NODE_PREFIX
    must resolve to the gadget node and never to the DAC's own ADC --
    linking the DAC's ADC into the DAC's own sink would be a feedback loop,
    not USB audio."""
    nodes = list_nodes(runner=_runner(PW_CLI_OUTPUT))
    match = find_node_by_prefix(GADGET_NODE_PREFIX, nodes)
    assert match == "alsa_input.platform-1000480000.usb.stereo-fallback"
    assert match != "alsa_input.platform-soc_107c000000_sound.stereo-fallback"


def test_find_node_by_prefix_returns_none_when_absent():
    assert find_node_by_prefix("nope", ["a", "b"]) is None


def test_find_node_exact_matches():
    nodes = list_nodes(runner=_runner(PW_CLI_OUTPUT))
    assert find_node_exact(TARGET_NODE, nodes) == TARGET_NODE


def test_find_node_exact_does_not_prefix_match():
    # A shorter name that is only a prefix of a real node must not match.
    nodes = ["alsa_output.platform-soc_107c000000_sound.stereo-fallback"]
    assert find_node_exact("alsa_output.platform-soc", nodes) is None


def test_find_node_exact_returns_none_when_absent():
    assert find_node_exact("nope", ["a", "b"]) is None


def test_link_pairs_maps_stereo_capture_to_playback():
    pairs = link_pairs("src", "dst")
    assert pairs == [
        ("src:capture_FL", "dst:playback_FL"),
        ("src:capture_FR", "dst:playback_FR"),
    ]


def test_connect_links_to_the_dac_sink_not_the_riaa_preamp():
    """input-processor is /usr/lib/ladspa/riaa.so -- a vinyl RIAA phono EQ
    curve. Routing USB audio through it would apply turntable equalisation
    and audibly wreck playback, so connect() must target the DAC sink
    directly and never reference input-processor in any pw-link call."""
    runner = _connect_runner()

    rc = connect(runner=runner)

    assert rc == 0
    link_calls = [
        call
        for call in runner.call_args_list
        if call.args[0][0] == "pw-link"
    ]
    assert link_calls, "connect() should have issued pw-link calls"
    for call in link_calls:
        cmd = call.args[0]
        assert any(TARGET_NODE in arg for arg in cmd)
        assert not any("input-processor" in arg for arg in cmd)


def test_disconnect_does_not_retry_when_nodes_missing():
    """disconnect() tears down links on shutdown; retrying for a node that
    is already gone just delays `systemctl --user stop` for no benefit, so
    it must resolve nodes once and give up immediately (unlike connect(),
    which legitimately waits for the gadget to appear)."""
    runner = _runner("")  # no nodes at all -> both lookups fail

    with patch("hifiberry_usbaudio.linker.time.sleep") as sleep:
        rc = disconnect(runner=runner)

    assert rc == 1
    sleep.assert_not_called()
    # Only a single "pw-cli ls Node" lookup, no retry loop.
    ls_calls = [
        call
        for call in runner.call_args_list
        if call.args[0][:2] == ["pw-cli", "ls"]
    ]
    assert len(ls_calls) == 1
