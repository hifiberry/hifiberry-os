from hifiberry_usbaudio.monitor import (
    diff_xruns,
    format_report,
    parse_alsa_status,
    read_xruns,
)

ALSA_STATUS = """\
state: RUNNING
owner_pid   : 1234
trigger_time: 1234.5
tstamp      : 1240.0
delay       : 512
avail       : 0
rate        : 192000
"""

PW_DUMP = """
[
  {"info": {"props": {"node.name": "alsa_output.dac"}, "change-mask": [], "xrun-count": 7}},
  {"info": {"props": {"node.name": "alsa_input.gadget"}, "change-mask": [], "xrun-count": 2}}
]
"""


def test_parse_alsa_status_extracts_state_and_rate():
    status = parse_alsa_status(ALSA_STATUS)
    assert status["state"] == "RUNNING"
    assert status["rate"] == 192000


def test_parse_alsa_status_handles_closed_device():
    assert parse_alsa_status("closed\n")["state"] is None


def test_read_xruns_maps_node_to_count():
    assert read_xruns(PW_DUMP) == {"alsa_output.dac": 7, "alsa_input.gadget": 2}


def test_diff_reports_only_increases():
    prev = {"a": 5, "b": 1}
    cur = {"a": 9, "b": 1}
    assert diff_xruns(prev, cur) == {"a": 4}


def test_diff_handles_new_nodes():
    assert diff_xruns({}, {"a": 3}) == {"a": 3}


def test_report_includes_the_rate_context():
    report = format_report(192000, {"alsa_output.dac": 4})
    assert "192000" in report
    assert "alsa_output.dac=4" in report


def test_report_says_clean_when_no_glitches():
    assert "clean" in format_report(48000, {}).lower()
