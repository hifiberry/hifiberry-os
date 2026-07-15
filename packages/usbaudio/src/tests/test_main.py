from unittest.mock import patch

import pytest

from hifiberry_usbaudio.main import build_parser, dispatch


def test_parser_accepts_the_three_actions():
    for action in ("connect", "disconnect", "monitor"):
        assert build_parser().parse_args([action]).action == action


def test_connect_dispatches_to_linker():
    with patch("hifiberry_usbaudio.main.linker.connect", return_value=0) as mock:
        assert dispatch(build_parser().parse_args(["connect"])) == 0
    mock.assert_called_once()


def test_disconnect_dispatches_to_linker():
    with patch("hifiberry_usbaudio.main.linker.disconnect", return_value=0) as mock:
        assert dispatch(build_parser().parse_args(["disconnect"])) == 0
    mock.assert_called_once()


def test_monitor_dispatches_to_monitor():
    with patch("hifiberry_usbaudio.main.monitor.run") as mock:
        dispatch(build_parser().parse_args(["monitor"]))
    mock.assert_called_once()


def test_monitor_accepts_interval_option():
    args = build_parser().parse_args(["monitor", "--interval", "10"])
    assert args.interval == 10


def test_monitor_accepts_card_filter_option():
    args = build_parser().parse_args(["monitor", "--card", "gadget"])
    assert args.card == "gadget"


def test_monitor_passes_interval_to_run():
    with patch("hifiberry_usbaudio.main.monitor.run") as mock:
        dispatch(build_parser().parse_args(["monitor", "--interval", "15"]))
    mock.assert_called_once()
    assert mock.call_args[1]["interval"] == 15


def test_monitor_passes_card_filter_to_run():
    with patch("hifiberry_usbaudio.main.monitor.run") as mock:
        dispatch(build_parser().parse_args(["monitor", "--card", "gadget"]))
    mock.assert_called_once()
    assert mock.call_args[1]["card_filter"] == "gadget"


def test_parser_accepts_state_action():
    assert build_parser().parse_args(["state"]).action == "state"


def test_state_dispatches_to_state_run():
    with patch("hifiberry_usbaudio.main.state.run") as mock:
        assert dispatch(build_parser().parse_args(["state"])) == 0
    mock.assert_called_once()


def test_state_accepts_interval_option():
    args = build_parser().parse_args(["state", "--interval", "10"])
    assert args.interval == 10


def test_state_accepts_card_filter_option():
    args = build_parser().parse_args(["state", "--card", "gadget"])
    assert args.card == "gadget"


def test_state_accepts_port_option():
    args = build_parser().parse_args(["state", "--port", "1090"])
    assert args.port == 1090


def test_state_port_defaults_to_1080():
    args = build_parser().parse_args(["state"])
    assert args.port == 1080


def test_state_passes_interval_to_run():
    with patch("hifiberry_usbaudio.main.state.run") as mock:
        dispatch(build_parser().parse_args(["state", "--interval", "15"]))
    mock.assert_called_once()
    assert mock.call_args[1]["interval"] == 15


def test_state_passes_card_filter_to_run():
    with patch("hifiberry_usbaudio.main.state.run") as mock:
        dispatch(build_parser().parse_args(["state", "--card", "gadget"]))
    mock.assert_called_once()
    assert mock.call_args[1]["card_filter"] == "gadget"


def test_state_passes_port_to_run():
    with patch("hifiberry_usbaudio.main.state.run") as mock:
        dispatch(build_parser().parse_args(["state", "--port", "1090"]))
    mock.assert_called_once()
    assert mock.call_args[1]["port"] == 1090


def test_state_without_card_rejects_loudly_instead_of_scanning_every_card():
    """CLI-level proof of the fix: `hifiberry-usbaudio state` with no --card
    (e.g. a misconfigured/un-pinned systemd unit) must fail loudly via
    state.run's own guard rather than silently default to scanning every
    /proc/asound card -- the exact mechanism that let the DAC's own
    playback be reported to ACR as the USB gadget playing."""
    with pytest.raises(ValueError):
        dispatch(build_parser().parse_args(["state"]))
