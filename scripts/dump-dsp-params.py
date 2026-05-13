#!/usr/bin/env python3
"""dump-dsp-params.py — dump DSP parameter memory in a diff-friendly form.

Reads every 32-bit cell of the ADAU145x parameter regions (DM0 = 0x0000..,
DM1 = 0x6000..) via the sigmatcpserver REST API and prints one line per cell.

Pair runs from two different systems (e.g. hbos-NG and the old HifiBerryOS)
and `diff` the outputs to find DSP-state differences.

Usage
-----
    dump-dsp-params.py [--host HOST] [--port PORT]
                       [--base-url URL]
                       [--include pmem]
                       [--start ADDR] [--end ADDR]
                       > out.txt

    # On the Pi (sigmatcpserver listens on 127.0.0.1:13141):
    dump-dsp-params.py > /tmp/dsp-params.txt

    # From another host, via nginx proxy:
    dump-dsp-params.py --base-url http://192.168.1.122/api/dsptoolkit \
        > /tmp/dsp-params.txt

Notes
-----
- Default region is DM0 (0x0000..0x1FFF) + DM1 (0x6000..0x7FFF). PMEM
  (0xC000..0xDFFF) is only included when --include pmem is passed; PMEM
  is the program itself and is already covered by /checksum.
- Control registers in 0xF000+ are NOT dumped — the /memory endpoint
  rejects them with "Invalid memory address" (valid range 0x0..0xDFFF).
- Output format: one line per cell, e.g.
      0x0000  0x00000001    0.000000060
- The cell address printed is the AdaU145x word address (4 bytes per cell).
"""
import argparse
import json
import sys
import urllib.request


DM0_START, DM0_END = 0x0000, 0x1FFF
DM1_START, DM1_END = 0x6000, 0x7FFF
PMEM_START, PMEM_END = 0xC000, 0xDFFF
CHUNK = 256  # cells per HTTP read


def read_chunk(base_url, addr, length):
    url = f"{base_url}/memory/{addr}/{length}"
    with urllib.request.urlopen(url, timeout=10) as r:
        payload = json.loads(r.read())
    return [int(v, 16) for v in payload["values"]]


def fxp(v):
    if v & 0x80000000:
        v -= 0x100000000
    return v / (1 << 24)


def dump_range(base_url, start, end, out):
    addr = start
    while addr <= end:
        n = min(CHUNK, end - addr + 1)
        try:
            values = read_chunk(base_url, addr, n)
        except Exception as e:
            print(f"# {addr:#06x}: read error: {e}", file=sys.stderr)
            return
        for i, v in enumerate(values):
            cell_addr = addr + i
            out.write(f"0x{cell_addr:04x}  0x{v & 0xffffffff:08x}    {fxp(v):+.9f}\n")
        addr += n


def main():
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--host", default="localhost",
                    help="sigmatcpserver host (default localhost)")
    ap.add_argument("--port", type=int, default=13141,
                    help="sigmatcpserver REST port (default 13141)")
    ap.add_argument("--base-url",
                    help="full base URL incl. path prefix; overrides --host/--port "
                         "(e.g. http://192.168.1.122/api/dsptoolkit)")
    ap.add_argument("--include", action="append", default=[],
                    choices=["pmem"],
                    help="extra regions to include (repeatable)")
    ap.add_argument("--start", type=lambda s: int(s, 0),
                    help="override start addr (skips default DM0/DM1 ranges)")
    ap.add_argument("--end", type=lambda s: int(s, 0),
                    help="override end addr (use with --start)")
    args = ap.parse_args()

    if (args.start is None) != (args.end is None):
        ap.error("--start and --end must be used together")

    base_url = args.base_url or f"http://{args.host}:{args.port}"
    base_url = base_url.rstrip("/")

    if args.start is not None:
        ranges = [("custom", args.start, args.end)]
    else:
        ranges = [("DM0", DM0_START, DM0_END), ("DM1", DM1_START, DM1_END)]
        if "pmem" in args.include:
            ranges.append(("PMEM", PMEM_START, PMEM_END))

    for name, s, e in ranges:
        print(f"# === {name} 0x{s:04x}..0x{e:04x} ({e - s + 1} cells) ===", file=sys.stderr)
        print(f"# === {name} 0x{s:04x}..0x{e:04x} ===")
        dump_range(base_url, s, e, sys.stdout)


if __name__ == "__main__":
    main()
