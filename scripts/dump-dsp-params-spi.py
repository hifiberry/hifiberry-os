#!/usr/bin/env python3
"""dump-dsp-params-spi.py — same output format as dump-dsp-params.py, but
reads directly from /dev/spidev0.0 instead of the sigmatcpserver REST API.

Use this on systems without the REST API (e.g. the old HifiBerryOS
image's Buildroot 2021.11 / dsptoolkit 0.21). Pair its output with the
hbos-NG REST-based dump (one line per cell, identical format) and `diff`
the two files to find DSP-state differences between the two OS images.

Reads DM0 (0x0000..0x1FFF) + DM1 (0x6000..0x7FFF) by default.

Usage
-----
    dump-dsp-params-spi.py [--include pmem]
                           [--start ADDR] [--end ADDR]
                           > out.txt
"""
import argparse
import sys

import spidev


DM0_START, DM0_END = 0x0000, 0x1FFF
DM1_START, DM1_END = 0x6000, 0x7FFF
PMEM_START, PMEM_END = 0xC000, 0xDFFF


def open_spi():
    s = spidev.SpiDev()
    s.open(0, 0)
    s.max_speed_hz = 1_000_000
    s.mode = 0
    return s


def read_cells(spi, addr, count):
    """Read `count` consecutive 32-bit cells starting at `addr`.
    Returns a list of signed ints (sign-extended from 32 bits)."""
    # ADAU145x SPI read: opcode 0x01, addr_hi, addr_lo, then 4*count zero bytes
    payload = [0x01, (addr >> 8) & 0xFF, addr & 0xFF] + [0] * (4 * count)
    resp = spi.xfer2(payload)
    out = []
    body = resp[3:]
    for i in range(count):
        b = body[4 * i: 4 * i + 4]
        v = (b[0] << 24) | (b[1] << 16) | (b[2] << 8) | b[3]
        if v & 0x80000000:
            v -= 0x100000000
        out.append(v)
    return out


def fxp(v):
    return v / (1 << 24)


# spidev IOCTL chokes on huge xfer2 buffers; chunk the reads
CHUNK = 256


def dump_range(spi, start, end, out):
    addr = start
    while addr <= end:
        n = min(CHUNK, end - addr + 1)
        values = read_cells(spi, addr, n)
        for i, v in enumerate(values):
            out.write(f"0x{addr + i:04x}  0x{v & 0xFFFFFFFF:08x}    {fxp(v):+.9f}\n")
        addr += n


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--include", action="append", default=[],
                    choices=["pmem"],
                    help="extra regions to include (repeatable)")
    ap.add_argument("--start", type=lambda s: int(s, 0))
    ap.add_argument("--end", type=lambda s: int(s, 0))
    args = ap.parse_args()

    if (args.start is None) != (args.end is None):
        ap.error("--start and --end must be used together")

    if args.start is not None:
        ranges = [("custom", args.start, args.end)]
    else:
        ranges = [("DM0", DM0_START, DM0_END), ("DM1", DM1_START, DM1_END)]
        if "pmem" in args.include:
            ranges.append(("PMEM", PMEM_START, PMEM_END))

    spi = open_spi()
    for name, s, e in ranges:
        print(f"# === {name} 0x{s:04x}..0x{e:04x} ({e - s + 1} cells) ===",
              file=sys.stderr)
        print(f"# === {name} 0x{s:04x}..0x{e:04x} ===")
        dump_range(spi, s, e, sys.stdout)


if __name__ == "__main__":
    main()
