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
# remove_gadget: exercised against a plain tmp_path tree (via root=).
#
# A plain filesystem cannot fully simulate real configfs semantics. On real
# hardware, rmdir-ing a group that still contains a *default* child group
# (configs/, functions/, strings/, configs/c.1/strings/) succeeds anyway --
# the kernel destroys the default group itself as part of removing its
# owner. That is precisely why the standard teardown recipe can rmdir
# configs/c.1 (which still "contains" the default configs/c.1/strings
# group) and finally the gadget root itself (which still "contains"
# configs/, functions/, strings/).
#
# A tmp_path directory has no such magic: os.rmdir requires the directory
# to be *actually* empty. Once create_gadget's os.makedirs has created a
# default-group directory as a real parent of something we mkdir'd inside
# it (e.g. "strings" as the parent of "strings/0x409"), that wrapper
# directory is left behind as an empty directory after we remove its
# child -- because our code correctly never rmdir's the default group
# itself. That leftover then blocks the *next* rmdir up the tree.
#
# This affects two of the six teardown_paths() entries: configs/c.1 (blocked
# by the leftover configs/c.1/strings) and the gadget root (blocked by the
# leftover configs/, functions/, strings/). It is not fixable by rearranging
# the fixture -- it is a real difference between configfs and POSIX rmdir
# semantics that only actual /sys can paper over. So instead of asserting a
# single remove_gadget() call tears down everything (which would only be
# true by accident, e.g. by silently swallowing the resulting ENOTEMPTY), we
# split coverage into what a plain filesystem CAN prove honestly:
#   - every entry remove_gadget successfully reaches gets removed
#     (proves ordering/coverage), and
#   - a genuine obstacle (the leftover default-group directory) raises
#     rather than being swallowed (proves the restored error propagation).
# ---------------------------------------------------------------------------


def _populate_gadget_tree(base_path, config=None):
    """Build the full directory/symlink skeleton create_gadget would leave.

    Deliberately does NOT write real attribute files (idVendor, UDC, etc.).
    On real configfs those are kernel-managed pseudo-files that vanish
    automatically when their owning directory is rmdir'd. A plain
    filesystem has no such magic: leaving real files in these dirs would
    make rmdir fail with ENOTEMPTY in a way that has nothing to do with our
    code. So we model only the part a tmp_path can faithfully represent:
    the directory/symlink structure and its ordering.

    Because this mirrors the *real* structure, os.makedirs necessarily also
    creates the default-group wrapper directories (configs/, functions/,
    strings/, configs/c.1/strings/) as real, literal parent directories --
    on a tmp_path they don't vanish on their own the way they would on real
    configfs. See the module comment above for what that means for tests
    built on this fixture.
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


def test_remove_gadget_removes_configs_branch_then_surfaces_real_failure(tmp_path):
    """The configs/c.1 branch, torn down against a realistic full tree.

    remove_gadget successfully removes the symlink and
    configs/c.1/strings/0x409 (genuine leaves, no children of their own).
    It then attempts rmdir on configs/c.1 itself -- on real configfs this
    succeeds because the kernel auto-destroys the leftover
    configs/c.1/strings default group; on a tmp_path that group is a real,
    still-present empty directory, so the rmdir genuinely fails with
    ENOTEMPTY. That failure must propagate, not be swallowed -- so this
    test asserts it raises, and that the two reachable entries were removed
    before the raise.
    """
    base = tmp_path / GADGET_NAME
    _populate_gadget_tree(base)

    symlink = base / "configs/c.1/uac2.usb0"
    configs_strings = base / "configs/c.1/strings/0x409"
    assert symlink.exists() or symlink.is_symlink()
    assert configs_strings.is_dir()

    with pytest.raises(OSError):
        remove_gadget(root=str(tmp_path))

    assert not symlink.is_symlink()
    assert not configs_strings.exists()


def test_remove_gadget_removes_functions_and_strings_leaves(tmp_path):
    """The functions/ and strings/ branches, torn down in isolation.

    Uses a narrower fixture with no configs/c.1 branch at all, so
    remove_gadget's walk skips those (absent) entries harmlessly and
    reaches functions/uac2.usb0 and strings/0x409, both genuine leaves that
    are removed cleanly. It then attempts the final rmdir on the gadget
    root -- which fails for the same class of reason as the test above
    (the leftover functions/ and strings/ default-group directories are
    still, literally, present on a tmp_path), and that failure must
    likewise propagate rather than be swallowed.
    """
    base = tmp_path / GADGET_NAME
    (base / "functions/uac2.usb0").mkdir(parents=True)
    (base / "strings/0x409").mkdir(parents=True)

    with pytest.raises(OSError):
        remove_gadget(root=str(tmp_path))

    assert not (base / "functions/uac2.usb0").exists()
    assert not (base / "strings/0x409").exists()


def test_remove_gadget_removes_bare_gadget_root_and_is_noop_on_repeat(tmp_path):
    """The final rmdir(base) step, and repeat-call safety.

    A tmp_path can't reproduce the kernel auto-destroying configs/,
    functions/, strings/ out from under the gadget root (see module
    comment), so this proves the base-removal code path the only honest
    way available: starting from a gadget root that is already down to
    nothing, matching the state real configfs would have reduced it to by
    the time this step runs. remove_gadget's own no-op branch is then
    exercised by calling it again once the gadget is gone.
    """
    base = tmp_path / GADGET_NAME
    base.mkdir()

    remove_gadget(root=str(tmp_path))
    assert not base.exists()

    remove_gadget(root=str(tmp_path))  # must not raise: gadget is now gone
    assert not base.exists()


def test_remove_gadget_is_noop_on_nonexistent_gadget(tmp_path):
    # Must not raise even though nothing exists under tmp_path.
    remove_gadget(root=str(tmp_path))


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
