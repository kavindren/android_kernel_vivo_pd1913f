#!/bin/bash

# =========================================================================
#  postbuild.sh - wraps the freshly built raw DTB into MTK Little Kernel
#  format (via wrap.py) and installs Image.gz + dtb.img into the
#  LineageOS device tree's prebuilt/ dir, where BoardConfig.mk's
#  TARGET_PREBUILT_KERNEL / TARGET_PREBUILT_DTB expect them.
#
#  Run this AFTER ./build.sh has completed successfully. It does not
#  compile anything itself - just packages and installs build.sh's
#  output, so it's safe to re-run any time kernel_out already has a
#  built Image.gz + raw dtb sitting in it.
# =========================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
OUT_DIR="$ROOT_DIR/kernel_out"
BOOT_DIR="$OUT_DIR/arch/arm64/boot"

RAW_KERNEL="$BOOT_DIR/Image.gz"
RAW_DTB="$BOOT_DIR/dts/mediatek/mt6768.dtb"
WRAPPED_DTB="$OUT_DIR/dtb.img"

DEVICE_PREBUILT_DIR="$ROOT_DIR/../lineage-19.1/device/vivo/1907N/prebuilt"

echo -e "${BLUE}--- postbuild.sh: packaging kernel build output ---${NC}"

if [ ! -f "$RAW_KERNEL" ]; then
    echo -e "${RED}Error: $RAW_KERNEL not found. Run ./build.sh first.${NC}"
    exit 1
fi

if [ ! -f "$RAW_DTB" ]; then
    echo -e "${RED}Error: $RAW_DTB not found. Run ./build.sh first.${NC}"
    exit 1
fi

if [ ! -d "$DEVICE_PREBUILT_DIR" ]; then
    echo -e "${RED}Error: device tree prebuilt dir not found at $DEVICE_PREBUILT_DIR${NC}"
    echo -e "${YELLOW}(expected the kernel and device trees checked out as siblings - adjust DEVICE_PREBUILT_DIR in this script if your layout differs)${NC}"
    exit 1
fi

echo -e "${YELLOW}Wrapping raw DTB into MTK LK format via wrap.py...${NC}"
python3 "$ROOT_DIR/wrap.py" "$RAW_DTB" "$WRAPPED_DTB"

if [ ! -f "$WRAPPED_DTB" ]; then
    echo -e "${RED}Error: wrap.py did not produce $WRAPPED_DTB${NC}"
    exit 1
fi

echo -e "${YELLOW}Backing up previously installed prebuilts...${NC}"
TS=$(date +%Y%m%d_%H%M%S)
[ -f "$DEVICE_PREBUILT_DIR/Image.gz" ] && cp -p "$DEVICE_PREBUILT_DIR/Image.gz" "$DEVICE_PREBUILT_DIR/Image.gz.prev_${TS}.bak"
[ -f "$DEVICE_PREBUILT_DIR/dtb.img" ] && cp -p "$DEVICE_PREBUILT_DIR/dtb.img" "$DEVICE_PREBUILT_DIR/dtb.img.prev_${TS}.bak"

echo -e "${YELLOW}Installing new Image.gz + dtb.img...${NC}"
cp -p "$RAW_KERNEL" "$DEVICE_PREBUILT_DIR/Image.gz"
cp -p "$WRAPPED_DTB" "$DEVICE_PREBUILT_DIR/dtb.img"

echo -e "${BLUE}-----------------------------------------------------${NC}"
echo -e "${GREEN}Done.${NC}"
echo -e "  Kernel: ${GREEN}$DEVICE_PREBUILT_DIR/Image.gz${NC} ($(du -h "$DEVICE_PREBUILT_DIR/Image.gz" | cut -f1))"
echo -e "  DTB:    ${GREEN}$DEVICE_PREBUILT_DIR/dtb.img${NC} ($(du -h "$DEVICE_PREBUILT_DIR/dtb.img" | cut -f1))"
echo -e "${YELLOW}Old prebuilts backed up alongside with a .prev_${TS}.bak suffix (if they existed).${NC}"
echo -e "${BLUE}Next: rebuild boot.img from the LineageOS tree (mka bootimage or a full build) and flash.${NC}"
echo -e "${BLUE}-----------------------------------------------------${NC}"
