#!/usr/bin/env python3
"""Convert a flat binary into a $readmemh-style hex file.

One 32-bit little-endian word per line, starting at word 0 of the image,
so the RTL memory model can load it with:

    $readmemh("program.hex", mem);

Usage: bin2hex.py input.bin output.hex
"""

import sys


def main() -> int:
    if len(sys.argv) != 3:
        print(__doc__.strip(), file=sys.stderr)
        return 1

    with open(sys.argv[1], "rb") as f:
        data = f.read()

    # Pad to a whole number of words.
    data += b"\x00" * (-len(data) % 4)

    with open(sys.argv[2], "w") as f:
        for i in range(0, len(data), 4):
            word = int.from_bytes(data[i:i + 4], "little")
            f.write(f"{word:08x}\n")

    return 0


if __name__ == "__main__":
    sys.exit(main())
