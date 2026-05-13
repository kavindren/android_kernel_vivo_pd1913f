#!/bin/bash

# =========================================================================
#  Vivo V17 Neo (PD1913F) Kernel Build Script
#  Author: kavindren
#  Target: Android 4.14.186 (MT6768)
#  Compiler: Clang r383902 (v11.0.1) with GCC 4.9 GAS
# =========================================================================

# Color defines
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuring paths
ROOT_DIR=$(pwd)
CLANG_DIR="$ROOT_DIR/prebuilts/clang/host/linux-x86/clang-r383902"
GCC64_DIR="$ROOT_DIR/prebuilts/gcc/linux-x86/aarch64/aarch64-linux-android-4.9"
OUT_DIR="$ROOT_DIR/kernel_out"
DEFAULT_DEFCONFIG="pd1913f_defconfig"

# Path to tools
CC_PATH="$CLANG_DIR/bin/clang"
LD_PATH="$CLANG_DIR/bin/ld.lld"
OBJCOPY_PATH="$CLANG_DIR/bin/llvm-objcopy"
STRIP_PATH="$CLANG_DIR/bin/llvm-strip"
NM_PATH="$CLANG_DIR/bin/llvm-nm"

# Environment variables
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=aarch64-linux-android-
export PATH="$CLANG_DIR/bin:$GCC64_DIR/bin:$PATH"

# Common build flags
MAKE_OPTS=(
    O="$OUT_DIR"
    ARCH=arm64
    CC="$CC_PATH"
    LD="$LD_PATH"
    OBJCOPY="$OBJCOPY_PATH"
    STRIP="$STRIP_PATH"
    NM="$NM_PATH"
    CLANG_TRIPLE=aarch64-linux-gnu-
    CROSS_COMPILE=aarch64-linux-android-
    LLVM=1
    LLVM_IAS=0
    KCFLAGS="-fcolor-diagnostics -Wno-unused-function -Wno-unused-variable"
)

# Processing arguments
FORCE_CLEAN=false
SELECTED_DEFCONFIG=""

for arg in "$@"; do
    case $arg in
        --force|-f)
            FORCE_CLEAN=true
            shift
            ;;
        *)
            # If argument is not a flag, it is a defconfig name
            SELECTED_DEFCONFIG=$arg
            shift
            ;;
    esac
done

# Check tools
if [ ! -f "$CC_PATH" ]; then
    echo -e "${RED}Error: Clang not found at $CC_PATH${NC}"
    exit 1
fi

# Force cleanup
if [ "$FORCE_CLEAN" = true ]; then
    echo -e "${CYAN}Force flag detected. Cleaning up $OUT_DIR...${NC}"
    rm -rf "$OUT_DIR"
fi

# Create the out directory
mkdir -p "$OUT_DIR"

# Configuration (.config)
if [ -n "$SELECTED_DEFCONFIG" ]; then
    # If custom defconfig was presented
    CONFIG_PATH="$ROOT_DIR/arch/arm64/configs/$SELECTED_DEFCONFIG"
    if [ -f "$CONFIG_PATH" ]; then
        echo -e "${BLUE}Generating configuration using custom defconfig: ${YELLOW}$SELECTED_DEFCONFIG${NC}..."
        make "${MAKE_OPTS[@]}" "$SELECTED_DEFCONFIG"
    else
        echo -e "${RED}Error: Defconfig '$SELECTED_DEFCONFIG' not found in arch/arm64/configs/${NC}"
        exit 1
    fi
elif [ ! -f "$OUT_DIR/.config" ]; then
    # In case .config was not found (clean build or --force parameter)
    echo -e "${BLUE}Using ${YELLOW}$DEFAULT_DEFCONFIG${BLUE} as default defconfig...${NC}"
    make "${MAKE_OPTS[@]}" "$DEFAULT_DEFCONFIG"
else
    # Incremental build
    echo -e "${CYAN}Found existing .config. Proceeding with incremental build...${NC}"
fi

# Compiling
echo -e "${YELLOW}Starting Kernel Compilation with $(nproc) jobs...${NC}"
make "${MAKE_OPTS[@]}" -j$(nproc) 2>&1 | tee build.log

# Checking the result
echo -e "${BLUE}-----------------------------------------------------${NC}"
if [ -f "$OUT_DIR/arch/arm64/boot/Image" ]; then
    echo -e "${GREEN}Build Successful!${NC}"
    echo -e "${CYAN}Kernel Image:${NC} $OUT_DIR/arch/arm64/boot/Image"
else
    echo -e "${RED}Build Failed! Check build.log.${NC}"
    exit 1
fi
echo -e "${BLUE}-----------------------------------------------------${NC}"
