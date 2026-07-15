from unittest.mock import MagicMock

from hifiberry_usbaudio.state import gadget_stream_state, post_state

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


def test_post_state_calls_acr_update_endpoint():
    run = MagicMock()
    post_state("playing", runner=run)
    cmd = run.call_args.args[0]
    assert "curl" in cmd[0]
    assert any("/api/player/usbaudio/update" in part for part in cmd)
    assert any('"state":"playing"' in part.replace(" ", "") for part in cmd)
