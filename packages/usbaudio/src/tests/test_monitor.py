import json
import logging

import pytest

from hifiberry_usbaudio.monitor import (
    _current_rate,
    diff_xruns,
    format_report,
    parse_alsa_status,
    read_xruns,
    run,
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


def test_read_xruns_signals_failure_distinctly_from_clean():
    # pw-dump crashed / emitted garbage. This must NOT look like "zero
    # xruns" -- a clean reading and a broken instrument are not the same
    # thing and must be distinguishable by the caller.
    assert read_xruns("not valid json {{{") is None


def test_read_xruns_returns_empty_dict_when_genuinely_no_nodes():
    # A parseable dump with no matching nodes is genuinely clean.
    assert read_xruns("[]") == {}


def test_diff_reports_only_increases():
    prev = {"a": 5, "b": 1}
    cur = {"a": 9, "b": 1}
    assert diff_xruns(prev, cur) == {"a": 4}


def test_diff_handles_new_nodes():
    assert diff_xruns({}, {"a": 3}) == {"a": 3}


def test_diff_reports_counter_reset_as_new_xruns():
    # Node restarted; its xrun-count reset from 9 down to 2. The absolute
    # drop isn't itself meaningful, but at minimum 2 xruns have occurred
    # since the restart and must be surfaced, not swallowed.
    prev = {"a": 9}
    cur = {"a": 2}
    assert diff_xruns(prev, cur) == {"a": 2}


def test_diff_reports_nothing_for_a_reset_to_exactly_zero():
    # Reset to exactly zero: nothing has happened yet since the restart,
    # so there's genuinely nothing to report yet.
    prev = {"a": 9}
    cur = {"a": 0}
    assert diff_xruns(prev, cur) == {}


def test_diff_reset_on_one_node_does_not_mask_a_normal_increase_on_another():
    prev = {"a": 9, "b": 1}
    cur = {"a": 2, "b": 4}
    assert diff_xruns(prev, cur) == {"a": 2, "b": 3}


def test_report_includes_the_rate_context():
    report = format_report(192000, {"alsa_output.dac": 4})
    assert "192000" in report
    assert "alsa_output.dac=4" in report


def test_report_says_clean_when_no_glitches():
    assert "clean" in format_report(48000, {}).lower()


def test_report_includes_card_identity_when_given():
    report = format_report(192000, {"n": 1}, card="card1:gadget")
    assert "card1:gadget" in report


# --- _current_rate: multi-card attribution -----------------------------
#
# On the target device both a HiFiBerry DAC card and the USB gadget card
# exist under /proc/asound. Tests below build a fake /proc/asound tree
# under tmp_path so nothing touches the real filesystem.


def _write_status(base_dir, card_dir, pcm, sub, state, rate, card_id=None):
    status_dir = base_dir / card_dir / pcm / sub
    status_dir.mkdir(parents=True, exist_ok=True)
    text = f"state: {state}\n"
    if rate is not None:
        text += f"rate: {rate}\n"
    (status_dir / "status").write_text(text)
    if card_id is not None:
        (base_dir / card_dir / "id").write_text(card_id)


def test_current_rate_reports_which_card_it_read(tmp_path):
    _write_status(tmp_path, "card0", "pcm0", "sub0", "RUNNING", 48000, card_id="dac")
    card, rate = _current_rate(base_dir=str(tmp_path))
    assert rate == 48000
    assert card is not None and ("card0" in card or "dac" in card)


def test_current_rate_no_running_card_returns_unknown(tmp_path):
    assert _current_rate(base_dir=str(tmp_path)) == (None, None)


def test_current_rate_flags_ambiguity_instead_of_picking_first_card(tmp_path):
    # Reproduces the real failure mode: a DAC card and the USB gadget card
    # are both RUNNING at different rates. Silently returning the first
    # one found in glob order would attribute a gadget xrun to the DAC's
    # rate (or vice versa) -- exactly the bug under test.
    _write_status(tmp_path, "card0", "pcm0", "sub0", "RUNNING", 48000, card_id="dac")
    _write_status(tmp_path, "card1", "pcm0", "sub0", "RUNNING", 192000, card_id="gadget")
    card, rate = _current_rate(base_dir=str(tmp_path))
    assert rate is None
    assert card is not None
    assert "48000" in card and "192000" in card


def test_current_rate_card_filter_disambiguates(tmp_path):
    _write_status(tmp_path, "card0", "pcm0", "sub0", "RUNNING", 48000, card_id="dac")
    _write_status(tmp_path, "card1", "pcm0", "sub0", "RUNNING", 192000, card_id="gadget")
    card, rate = _current_rate(card_filter="card1", base_dir=str(tmp_path))
    assert rate == 192000
    assert card is not None and ("card1" in card or "gadget" in card)


# --- run(): first-poll priming, card attribution, instrument failure ---


class _FakeResult:
    def __init__(self, stdout):
        self.stdout = stdout


def _runner_from(outputs):
    it = iter(outputs)

    def runner(*_args, **_kwargs):
        return _FakeResult(next(it))

    return runner


def _dump(node, xrun_count):
    return json.dumps(
        [{"info": {"props": {"node.name": node}, "xrun-count": xrun_count}}]
    )


def test_run_primes_baseline_on_first_poll_without_reporting(tmp_path, caplog):
    # A node already carries 400 stale xruns from before we started
    # watching. The first poll must establish the baseline, not report
    # the stale count as a fresh glitch.
    outputs = [_dump("n", 400), _dump("n", 400)]
    caplog.set_level(logging.WARNING)
    run(runner=_runner_from(outputs), sleeper=lambda _s: None, base_dir=str(tmp_path))
    assert caplog.records == []


def test_run_reports_increase_after_priming(tmp_path, caplog):
    outputs = [_dump("n", 5), _dump("n", 9)]
    caplog.set_level(logging.WARNING)
    run(runner=_runner_from(outputs), sleeper=lambda _s: None, base_dir=str(tmp_path))
    assert len(caplog.records) == 1
    assert "n=4" in caplog.text


def test_run_reports_card_identity_alongside_the_rate(tmp_path, caplog):
    _write_status(tmp_path, "card0", "pcm0", "sub0", "RUNNING", 48000, card_id="dac")
    outputs = [_dump("n", 5), _dump("n", 9)]
    caplog.set_level(logging.WARNING)
    run(runner=_runner_from(outputs), sleeper=lambda _s: None, base_dir=str(tmp_path))
    assert "48000" in caplog.text
    assert "card0" in caplog.text or "dac" in caplog.text


def test_run_logs_distinctly_on_unparseable_pw_dump(tmp_path, caplog):
    outputs = ["not valid json {{{"]
    caplog.set_level(logging.WARNING)
    run(runner=_runner_from(outputs), sleeper=lambda _s: None, base_dir=str(tmp_path))
    assert len(caplog.records) == 1
    text = caplog.text.lower()
    # Must not read as a normal clean poll (e.g. "clean (no xruns)"), and
    # must clearly signal that the instrument itself failed.
    assert "clean (no xruns)" not in text
    assert "unknown" in text or "fail" in text
