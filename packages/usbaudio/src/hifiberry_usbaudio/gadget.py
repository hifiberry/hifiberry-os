"""UAC2 USB audio gadget setup via configfs.

Only the dwc2 controller can act as a USB device. If /sys/class/udc is empty
the kernel has no device controller -- almost always because config.txt still
says dr_mode=host (see config-configtxt --enable-usb-gadget).
"""

import logging
import os

GADGET_NAME = "hifiberry"
CONFIGFS_ROOT = "/sys/kernel/config/usb_gadget"

DEFAULT_RATES = [44100, 48000, 88200, 96000, 176400, 192000]


class NoUDCError(Exception):
    """Raised when no USB Device Controller is available."""


class GadgetConfig:
    def __init__(self, rates=None, channels=2, sample_size=3):
        self.rates = list(rates) if rates else list(DEFAULT_RATES)
        self.channels = channels
        self.sample_size = sample_size

    @property
    def chmask(self):
        """Channel mask: 2 channels -> 0b11 -> 3."""
        return (1 << self.channels) - 1


def build_gadget_tree(config):
    """Return (relative_path, contents) pairs describing the configfs gadget."""
    rates = ",".join(str(r) for r in config.rates)
    chmask = str(config.chmask)
    ssize = str(config.sample_size)
    return [
        ("idVendor", "0x1d6b"),           # Linux Foundation
        ("idProduct", "0x0104"),          # Multifunction Composite Gadget
        ("bcdDevice", "0x0100"),
        ("bcdUSB", "0x0200"),
        ("strings/0x409/manufacturer", "HiFiBerry"),
        ("strings/0x409/product", "HiFiBerry USB Audio"),
        ("strings/0x409/serialnumber", "0000000000000000"),
        ("configs/c.1/strings/0x409/configuration", "UAC2"),
        ("configs/c.1/MaxPower", "250"),
        # p_/c_ naming is easy to invert; configure both directions identically.
        ("functions/uac2.usb0/c_srate", rates),
        ("functions/uac2.usb0/p_srate", rates),
        ("functions/uac2.usb0/c_ssize", ssize),
        ("functions/uac2.usb0/p_ssize", ssize),
        ("functions/uac2.usb0/c_chmask", chmask),
        ("functions/uac2.usb0/p_chmask", chmask),
    ]


def find_udc(udc_dir="/sys/class/udc"):
    """Return the first available UDC name."""
    try:
        entries = sorted(os.listdir(udc_dir))
    except FileNotFoundError:
        entries = []
    if not entries:
        raise NoUDCError(
            "No USB Device Controller found. config.txt likely still has "
            "dr_mode=host -- run 'config-configtxt --enable-usb-gadget' and reboot."
        )
    return entries[0]


def _write(path, value):
    with open(path, "w") as handle:
        handle.write(value)


def _unbind(base):
    """Write a newline to UDC to release the gadget from its controller.

    Safe to call whether or not the gadget is currently bound -- configfs
    accepts an unbind write even when nothing is bound.
    """
    udc_path = os.path.join(base, "UDC")
    if os.path.exists(udc_path):
        _write(udc_path, "\n")
        logging.info("UAC2 gadget unbound")


def create_gadget(config=None, root=CONFIGFS_ROOT):
    """Create and bind the UAC2 gadget. Requires root.

    Idempotent: if the gadget already exists and is bound, it is unbound
    first (configfs refuses attribute writes on a bound gadget with EBUSY),
    then attributes are rewritten and the gadget is rebound.
    """
    config = config or GadgetConfig()
    base = os.path.join(root, GADGET_NAME)
    udc_path = os.path.join(base, "UDC")

    if os.path.exists(udc_path):
        try:
            with open(udc_path) as handle:
                already_bound = bool(handle.read().strip())
        except OSError:
            already_bound = False
        if already_bound:
            _unbind(base)

    for rel, value in build_gadget_tree(config):
        full = os.path.join(base, rel)
        os.makedirs(os.path.dirname(full), exist_ok=True)
        _write(full, value)

    link = os.path.join(base, "configs/c.1/uac2.usb0")
    if not os.path.exists(link):
        os.symlink(os.path.join(base, "functions/uac2.usb0"), link)

    udc = find_udc()
    _write(udc_path, udc)
    logging.info(f"UAC2 gadget bound to {udc}")
    return udc


def teardown_paths(base):
    """Return the configfs paths under `base` to remove, in a safe order.

    Pure function (no I/O) so the ordering can be unit tested without
    touching /sys. configfs directories cannot be `rm -rf`'d: each entry
    must be removed only after everything that depends on it is gone, and
    directories must be removed with rmdir (empty-dir only).
    """
    return [
        os.path.join(base, "configs/c.1/uac2.usb0"),  # symlink first
        os.path.join(base, "configs/c.1/strings/0x409"),
        os.path.join(base, "configs/c.1"),
        os.path.join(base, "functions/uac2.usb0"),
        os.path.join(base, "strings/0x409"),
        base,  # gadget root last
    ]


def remove_gadget(root=CONFIGFS_ROOT):
    """Unbind and fully tear down the gadget.

    Safe to call when the gadget does not exist (no-op) or has already
    been torn down: each teardown_paths() entry is only acted on if it is
    still present, so repeating the call finds nothing left to do. Any
    other failure -- e.g. EBUSY because the gadget is still bound, or a
    permissions error -- propagates as an OSError. A real teardown
    failure must be visible to the caller, not reported as success.

    The default groups configfs creates automatically -- configs/,
    functions/, strings/, and configs/c.1/strings/ -- are deliberately
    never rmdir'd here. configfs refuses a direct rmdir of a default
    group (EPERM) and instead destroys each one itself once the group
    that owns it (the gadget root, or configs/c.1) is removed.
    teardown_paths() reflects this: it lists only the entries this
    module created itself, not the kernel-managed default groups.
    """
    base = os.path.join(root, GADGET_NAME)
    if not os.path.exists(base):
        return

    _unbind(base)

    for path in teardown_paths(base):
        if os.path.islink(path):
            os.remove(path)
        elif os.path.isdir(path):
            os.rmdir(path)

    logging.info("UAC2 gadget removed")
