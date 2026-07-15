import pytest

from hifiberry_usbaudio.gadget import (
    GadgetConfig,
    NoUDCError,
    build_gadget_tree,
    find_udc,
)


def test_default_config_advertises_up_to_192k():
    cfg = GadgetConfig()
    assert cfg.rates == [44100, 48000, 88200, 96000, 176400, 192000]
    assert cfg.channels == 2
    assert cfg.sample_size == 3  # 24-bit


def test_tree_sets_hifiberry_strings():
    tree = dict(build_gadget_tree(GadgetConfig()))
    assert tree["strings/0x409/manufacturer"] == "HiFiBerry"
    assert "HiFiBerry" in tree["strings/0x409/product"]


def test_tree_configures_both_directions_with_same_rates():
    """p_/c_ direction naming in usb_f_uac2 is easy to invert; set both."""
    tree = dict(build_gadget_tree(GadgetConfig()))
    expected = "44100,48000,88200,96000,176400,192000"
    assert tree["functions/uac2.usb0/c_srate"] == expected
    assert tree["functions/uac2.usb0/p_srate"] == expected
    assert tree["functions/uac2.usb0/c_ssize"] == "3"
    assert tree["functions/uac2.usb0/p_ssize"] == "3"
    assert tree["functions/uac2.usb0/c_chmask"] == "3"  # stereo
    assert tree["functions/uac2.usb0/p_chmask"] == "3"


def test_tree_respects_custom_rate_list():
    tree = dict(build_gadget_tree(GadgetConfig(rates=[48000])))
    assert tree["functions/uac2.usb0/c_srate"] == "48000"


def test_find_udc_returns_first_entry(tmp_path):
    (tmp_path / "1000480000.usb").mkdir()
    assert find_udc(udc_dir=str(tmp_path)) == "1000480000.usb"


def test_find_udc_raises_when_empty(tmp_path):
    with pytest.raises(NoUDCError):
        find_udc(udc_dir=str(tmp_path))
