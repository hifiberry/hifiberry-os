import os

import pytest

from hifiberry_usbaudio import gadget
from hifiberry_usbaudio.gadget import (
    GADGET_NAME,
    GadgetConfig,
    NoUDCError,
    build_gadget_tree,
    create_gadget,
    find_udc,
    remove_gadget,
    teardown_paths,
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


# ---------------------------------------------------------------------------
# teardown_paths: pure function, no /sys, no root required.
# ---------------------------------------------------------------------------


def test_teardown_paths_order():
    """Ordering must respect configfs' rmdir-only, dependency-first semantics."""
    base = "/sys/kernel/config/usb_gadget/hifiberry"
    paths = teardown_paths(base)
    idx = {p: i for i, p in enumerate(paths)}

    symlink = os.path.join(base, "configs/c.1/uac2.usb0")
    configs_strings = os.path.join(base, "configs/c.1/strings/0x409")
    configs_c1 = os.path.join(base, "configs/c.1")
    functions = os.path.join(base, "functions/uac2.usb0")
    strings = os.path.join(base, "strings/0x409")

    for p in (symlink, configs_strings, configs_c1, functions, strings, base):
        assert p in idx, f"{p} missing from teardown_paths"

    # the symlink must be removed before its containing config dir
    assert idx[symlink] < idx[configs_c1]
    # the config's strings dir must be removed before the config dir itself
    assert idx[configs_strings] < idx[configs_c1]
    # functions and top-level strings dirs must be removed before the gadget root
    assert idx[functions] < idx[base]
    assert idx[strings] < idx[base]
    # the gadget root must be removed last
    assert paths[-1] == base


def test_teardown_paths_covers_every_dir_implied_by_build_gadget_tree():
    """No orphaned directory: every dir build_gadget_tree writes into must be
    torn down. Derived from build_gadget_tree's own output so the two lists
    cannot drift apart.
    """
    base = "/sys/kernel/config/usb_gadget/hifiberry"
    implied_dirs = {
        os.path.dirname(os.path.join(base, rel))
        for rel, _value in build_gadget_tree(GadgetConfig())
    }
    paths = set(teardown_paths(base))

    for directory in implied_dirs:
        assert directory in paths, f"{directory} not covered by teardown_paths"


# ---------------------------------------------------------------------------
# remove_gadget: exercised against a plain tmp_path tree (via root=), which
# can prove ordering/coverage/no-op safety but cannot simulate real configfs
# semantics (EBUSY, rmdir-only enforcement) -- those require actual /sys.
# ---------------------------------------------------------------------------


def _populate_gadget_tree(base_path, config=None):
    """Build the directory/symlink skeleton remove_gadget is responsible for.

    Deliberately does NOT write real attribute files (idVendor, UDC, etc.).
    On real configfs those are kernel-managed pseudo-files that vanish
    automatically when their owning directory is rmdir'd -- that's *why*
    the standard teardown recipe can rmdir a "non-empty-looking" directory.
    A plain filesystem has no such magic: leaving real files in these dirs
    would make rmdir fail with ENOTEMPTY in a way that has nothing to do
    with our code and everything to do with the fixture lying about what
    configfs actually looks like. So we model only the part a tmp_path can
    faithfully represent: the directory/symlink structure and its ordering.
    """
    config = config or GadgetConfig()
    implied_dirs = {
        os.path.dirname(os.path.join(str(base_path), rel))
        for rel, _value in build_gadget_tree(config)
    }
    for directory in implied_dirs:
        os.makedirs(directory, exist_ok=True)
    (base_path / "configs/c.1/uac2.usb0").symlink_to(
        base_path / "functions/uac2.usb0"
    )
    return base_path


def test_remove_gadget_tears_down_everything(tmp_path):
    """Verify that remove_gadget removes all paths declared by teardown_paths.

    A tmp_path fixture cannot simulate real configfs semantics (EBUSY,
    rmdir-only enforcement, auto-destruction of default groups), but it can
    verify that our code attempts to remove every directory and symlink that
    teardown_paths declares necessary.
    """
    base = tmp_path / GADGET_NAME
    _populate_gadget_tree(base)

    remove_gadget(root=str(tmp_path))

    # Verify that every path teardown_paths says should be removed is gone.
    for path in teardown_paths(str(base)):
        assert not os.path.exists(path), f"{path} still exists after remove_gadget"


def test_remove_gadget_is_noop_on_nonexistent_gadget(tmp_path):
    # Must not raise even though nothing exists under tmp_path.
    remove_gadget(root=str(tmp_path))


def test_remove_gadget_is_noop_on_second_call(tmp_path):
    base = tmp_path / GADGET_NAME
    _populate_gadget_tree(base)

    remove_gadget(root=str(tmp_path))
    remove_gadget(root=str(tmp_path))  # must not raise: gadget is now gone

    assert not base.exists()


# ---------------------------------------------------------------------------
# create_gadget idempotency. A tmp_path filesystem can't reproduce configfs'
# EBUSY-on-bound-writes behaviour, so these tests exercise the actual
# ordering of our idempotency logic (unbind-before-rewrite) and confirm
# repeated calls don't raise, rather than proving EBUSY is avoided.
# ---------------------------------------------------------------------------


def test_create_gadget_unbinds_before_rewriting_when_already_bound(
    tmp_path, monkeypatch
):
    base = tmp_path / GADGET_NAME
    _populate_gadget_tree(base)
    (base / "UDC").write_text("existing-udc")

    monkeypatch.setattr(gadget, "find_udc", lambda: "existing-udc")

    calls = []
    real_write = gadget._write

    def spy_write(path, value):
        calls.append((path, value))
        real_write(path, value)

    monkeypatch.setattr(gadget, "_write", spy_write)

    udc = create_gadget(root=str(tmp_path))

    assert udc == "existing-udc"
    udc_path = str(base / "UDC")
    unbind_calls = [i for i, c in enumerate(calls) if c == (udc_path, "\n")]
    assert unbind_calls, "expected an unbind write before rewriting attributes"
    # the unbind must happen before any other write, and the final write
    # must be the rebind.
    assert unbind_calls[0] == 0
    assert calls[-1] == (udc_path, "existing-udc")


def test_create_gadget_is_idempotent(tmp_path, monkeypatch):
    monkeypatch.setattr(gadget, "find_udc", lambda: "dummyudc")

    create_gadget(root=str(tmp_path))
    udc = create_gadget(root=str(tmp_path))  # second call must not raise

    assert udc == "dummyudc"
    assert (tmp_path / GADGET_NAME / "UDC").read_text() == "dummyudc"
