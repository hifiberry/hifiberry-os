import json
import logging
from unittest.mock import MagicMock

import pytest

from hifiberry_usbaudio.monitor import discover_status_paths
from hifiberry_usbaudio.state import gadget_stream_state, post_state, run

RUNNING = "state: RUNNING\nrate        : 192000\n"
CLOSED = "closed\n"


def test_running_substream_means_playing(tmp_path):
    path = tmp_path / "status"
    path.write_text(RUNNING)
    assert gadget_stream_state([str(path)]) == "playing"


def test_closed_substream_means_stopped(tmp_path):
    path = tmp_path / "status"
    path.write_text(CLOSED)
    assert gadget_stream_state([str(path)]) == "stopped"


def test_missing_status_file_means_stopped():
    assert gadget_stream_state(["/nonexistent/status"]) == "stopped"


def test_no_paths_means_stopped():
    assert gadget_stream_state([]) == "stopped"


# --- wrong-card bug: the DAC's own playback must not report the gadget --
# as "playing". This is the same bug class fixed in monitor.py's
# _current_rate (Task 8): the device has BOTH a HiFiBerry DAC card and (once
# bound) a USB gadget card under /proc/asound, and nothing here may assume
# any particular status path belongs to the gadget just because it exists.


def _write_status(base_dir, card_dir, pcm, sub, state, card_id=None):
    status_dir = base_dir / card_dir / pcm / sub
    status_dir.mkdir(parents=True, exist_ok=True)
    (status_dir / "status").write_text(f"state: {state}\n")
    if card_id is not None:
        (base_dir / card_dir / "id").write_text(card_id)


def test_gadget_stream_state_misattributes_dac_playback_without_card_scoping(tmp_path):
    """Reproduction of the reported bug: the DAC card is RUNNING (someone is
    playing local music) while the gadget card itself is idle. Feeding
    gadget_stream_state every status path under /proc/asound -- i.e. what
    happens with no card scoping at all -- wrongly reports "playing" for
    the gadget/Mac."""
    _write_status(tmp_path, "card0", "pcm0", "sub0", "RUNNING", card_id="dac")
    _write_status(tmp_path, "card1", "pcm0", "sub0", "CLOSED", card_id="gadget")

    unscoped_paths = discover_status_paths(base_dir=str(tmp_path))
    assert gadget_stream_state(unscoped_paths) == "playing"  # WRONG: gadget is idle


def test_discover_status_paths_scoped_to_gadget_card_reports_correctly(tmp_path):
    """The fix: scoping discovery to the gadget's own card (by card_filter)
    excludes the DAC's status entirely, so gadget_stream_state reflects
    only the gadget -- exactly the card_filter/base_dir mechanism
    monitor.py already uses for rate attribution."""
    _write_status(tmp_path, "card0", "pcm0", "sub0", "RUNNING", card_id="dac")
    _write_status(tmp_path, "card1", "pcm0", "sub0", "CLOSED", card_id="gadget")

    scoped_paths = discover_status_paths(base_dir=str(tmp_path), card_filter="gadget")
    assert gadget_stream_state(scoped_paths) == "stopped"


def test_discover_status_paths_scoped_to_gadget_card_detects_its_own_playback(tmp_path):
    _write_status(tmp_path, "card0", "pcm0", "sub0", "CLOSED", card_id="dac")
    _write_status(tmp_path, "card1", "pcm0", "sub0", "RUNNING", card_id="gadget")

    scoped_paths = discover_status_paths(base_dir=str(tmp_path), card_filter="gadget")
    assert gadget_stream_state(scoped_paths) == "playing"


# --- post_state: stdlib urllib, no curl, failures never logged as success -


class _FakeResponse:
    def __init__(self, status=200):
        self.status = status

    def __enter__(self):
        return self

    def __exit__(self, *exc_info):
        return False


def test_post_state_uses_urllib_not_curl():
    opener = MagicMock(return_value=_FakeResponse(200))
    post_state("playing", opener=opener)

    opener.assert_called_once()
    request = opener.call_args.args[0]
    assert request.full_url == "http://localhost:1080/api/player/usbaudio/update"
    assert request.get_method() == "POST"
    body = json.loads(request.data.decode("utf-8"))
    assert body == {"type": "state_changed", "state": "playing"}


def test_post_state_logs_success_only_on_2xx(caplog):
    opener = MagicMock(return_value=_FakeResponse(200))
    caplog.set_level(logging.INFO)
    post_state("playing", opener=opener)
    assert "Reported state 'playing'" in caplog.text


def test_post_state_does_not_log_success_on_http_error(caplog):
    import urllib.error

    opener = MagicMock(side_effect=urllib.error.HTTPError(
        "http://localhost:1080/api/player/usbaudio/update", 503,
        "Service Unavailable", None, None,
    ))
    caplog.set_level(logging.DEBUG)
    post_state("playing", opener=opener)
    assert "Reported state" not in caplog.text
    assert "503" in caplog.text


def test_post_state_does_not_log_success_on_connection_refused(caplog):
    import urllib.error

    opener = MagicMock(side_effect=urllib.error.URLError("Connection refused"))
    caplog.set_level(logging.DEBUG)
    post_state("playing", opener=opener)
    assert "Reported state" not in caplog.text


def test_post_state_does_not_crash_on_failure():
    import urllib.error

    opener = MagicMock(side_effect=urllib.error.URLError("Connection refused"))
    post_state("playing", opener=opener)  # must not raise


def test_post_state_does_not_log_success_on_non_2xx_status(caplog):
    opener = MagicMock(return_value=_FakeResponse(500))
    caplog.set_level(logging.DEBUG)
    post_state("playing", opener=opener)
    assert "Reported state" not in caplog.text


# --- run(): poll loop posts only on state change --------------------------


def test_run_posts_only_when_state_changes(tmp_path):
    _write_status(tmp_path, "card1", "pcm0", "sub0", "CLOSED", card_id="gadget")

    poster = MagicMock()
    calls = {"n": 0}

    def sleeper(_interval):
        calls["n"] += 1
        if calls["n"] >= 4:
            raise StopIteration

    run(
        base_dir=str(tmp_path),
        card_filter="gadget",
        poster=poster,
        sleeper=sleeper,
    )

    # Stopped the whole time -- only the first poll should have posted.
    assert poster.call_count == 1
    assert poster.call_args.args[0] == "stopped"


def test_run_posts_again_when_state_flips(tmp_path):
    status_path = tmp_path / "card1" / "pcm0" / "sub0" / "status"
    status_path.parent.mkdir(parents=True)
    status_path.write_text("state: CLOSED\n")
    (tmp_path / "card1" / "id").write_text("gadget")

    poster = MagicMock()
    calls = {"n": 0}

    def sleeper(_interval):
        calls["n"] += 1
        if calls["n"] == 2:
            status_path.write_text("state: RUNNING\nrate: 48000\n")
        if calls["n"] >= 3:
            raise StopIteration

    run(
        base_dir=str(tmp_path),
        card_filter="gadget",
        poster=poster,
        sleeper=sleeper,
    )

    assert [c.args[0] for c in poster.call_args_list] == ["stopped", "playing"]


def test_run_is_card_scoped_by_default_via_card_filter_argument(tmp_path):
    """run() must accept a card_filter and use it for discovery -- it must
    not hardcode any particular gadget card name."""
    _write_status(tmp_path, "card0", "pcm0", "sub0", "RUNNING", card_id="dac")
    _write_status(tmp_path, "card1", "pcm0", "sub0", "CLOSED", card_id="gadget")

    poster = MagicMock()

    def sleeper(_interval):
        raise StopIteration

    run(
        base_dir=str(tmp_path),
        card_filter="gadget",
        poster=poster,
        sleeper=sleeper,
    )

    assert poster.call_args.args[0] == "stopped"
