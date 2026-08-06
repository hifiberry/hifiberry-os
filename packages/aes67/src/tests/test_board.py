from hifiberry_aes67 import board


def test_cm5_gets_the_low_latency_default():
    assert board.default_latency_msec("Raspberry Pi Compute Module 5 Lite Rev 1.0") == 3


def test_pi5_gets_the_low_latency_default():
    assert board.default_latency_msec("Raspberry Pi 5 Model B Rev 1.0") == 3


def test_pi4_gets_the_conservative_default():
    """Measured: 3ms gives 1320 xruns on a Pi 4, 20ms gives none."""
    assert board.default_latency_msec("Raspberry Pi 4 Model B Rev 1.1") == 20


def test_cm4_gets_the_conservative_default():
    assert board.default_latency_msec("Raspberry Pi Compute Module 4 Rev 1.0") == 20


def test_unknown_board_is_conservative():
    assert board.default_latency_msec("Some Other SBC") == 20


def test_missing_model_is_conservative():
    assert board.default_latency_msec(None) == 20


def test_model_reads_device_tree(tmp_path):
    path = tmp_path / "model"
    # /proc/device-tree strings are NUL-terminated.
    path.write_bytes(b"Raspberry Pi 4 Model B Rev 1.1\x00")
    assert board.model(str(path)) == "Raspberry Pi 4 Model B Rev 1.1"


def test_model_returns_none_when_absent(tmp_path):
    assert board.model(str(tmp_path / "nope")) is None
