#!/bin/env python

# =========================================================================
# wrap.py - used to patch DTB for Vivo V17 Neo (PD1913F) Little Kernel (LK)
# Author: kavindren
# Target: Android 4.14.186 (MT6768)
# =========================================================================

import struct
import sys

# Captured once from the stock PD1913F dtb.img header (offsets 0x00-0x3F).
# Only the size/offset fields patched below actually vary per build; the
# rest of the header is constant on this device, so a stock dtb file is
# no longer needed at patch time.
STOCK_MTK_DTB_HEADER = bytes.fromhex(
    "d7 b7 ab 1e 00 01 80 35 00 00 00 20 00 00 00 20"
    "00 00 00 01 00 00 00 20 00 00 08 00 00 00 00 00"
    "00 01 7f f5 00 00 00 40 00 00 00 00 00 00 00 00"
    "00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00"
)

def patch_header(custom_dtb, output_file):
    header = bytearray(STOCK_MTK_DTB_HEADER)

    with open(custom_dtb, 'rb') as f:
        new_dtb_data = f.read()

    new_dtb_len = len(new_dtb_data)
    total_size = new_dtb_len + len(header)  # FDT + header

    # Field 0x04: Overall size (Header + FDT)
    struct.pack_into('>I', header, 0x04, total_size)

    # Field 0x20: Only FDT data size
    struct.pack_into('>I', header, 0x20, new_dtb_len)

    # Field 0x24: Beginning of FDT offset (always 0x40 like in stock)
    struct.pack_into('>I', header, 0x24, 0x40)

    with open(output_file, 'wb') as f:
        f.write(header)
        f.write(new_dtb_data)

    print(f"--- Patched MTK DTB ---")
    print(f"FDT Size:   {new_dtb_len} bytes")
    print(f"Total Size: {total_size} bytes")
    print(f"Output:     {output_file}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python3 wrap.py <custom_dtb> <output_file>")
    else:
        patch_header(sys.argv[1], sys.argv[2])
