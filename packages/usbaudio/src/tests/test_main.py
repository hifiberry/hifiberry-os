from unittest.mock import patch

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
