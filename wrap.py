#!/bin/env python

# =========================================================================
# wrap.py - used to patch DTB for Vivo V17 Neo (PD1913F) Little Kernel (LK)
# Author: kavindren
# Target: Android 4.14.186 (MT6768)
# =========================================================================

import struct
import sys

def patch_stock_header(stock_dtb, custom_dtb, output_file):
    with open(stock_dtb, 'rb') as f:
        header = bytearray(f.read(64))
    
    with open(custom_dtb, 'rb') as f:
        new_dtb_data = f.read()

    new_dtb_len = len(new_dtb_data)
    total_size = new_dtb_len + 64 # FDT + header

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
    if len(sys.argv) < 4:
        print("Usage: python3 wrap.py <stock_dtb> <custom_dtb> <output_file>")
    else:
        patch_stock_header(sys.argv[1], sys.argv[2], sys.argv[3])
