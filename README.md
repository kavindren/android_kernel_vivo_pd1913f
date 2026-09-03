# Custom kernel sources for Vivo V17 Neo (PD1913F)

![Kernel Version](https://img.shields.io/badge/Kernel-4.14.186-blue.svg)
![Target Architecture](https://img.shields.io/badge/Arch-ARM64-orange.svg)
![Android Version](https://img.shields.io/badge/Android-12-green.svg)
![Status](https://img.shields.io/badge/Status-Work%20in%20Progress-yellow.svg)

Custom kernel for **Vivo V17 Neo / S1 (MT6768)** based on official vivo V23 5G kernel sources. 
This project is focused on updating security components and adding more tools (KernelSU).

---

## Device info
| Characteristics | Description |
| :--- | :--- |
| **SoC** | MediaTek MT6768 (Helio P65) |
| **Device Codename** | PD1913F / 1907N |
| **Current OS** | Android 12 (Funtouch OS 10.5) |
| **Kernel Base** | 4.14.186 |

---

## Features
- [x] **KernelSU-Next Integration**: Built-in root manager on kernel level (manual hooks).

---

## Status
> **Warning**: The kernel is in the active development phase (BETA). **Use at your own risk.**

- **Working:**
  - [x] Booting in userspace (Android)
  - [x] Touchscreen & display
  - [x] Root (KernelSU-Next)
  - [x] Sound & microphone
  - [x] Battery percentage
  - [x] Basic charging
  - [x] Temperature sensors
  - [x] RIL, Wi-Fi, Bluetooth
  - [x] USB & MTP
  - [x] Fingerprint
  - [x] Camera
- **In progress (Known issues):**
  - [ ] **NFC**
  - [ ] **vivo FlashCharge** - impossible due to missing vivo drivers

---

### Prerequisites
Make sure you have cloned or prepared the required toolchains and prebuilts tree (e.g., from an AOSP/TWRP manifest) in the `prebuilts/` directory before building.

### 1. Compile the Kernel
Run the build script located at the root of the source tree:

```bash
./build.sh
```

> Note: The `build.sh` script accepts two optional arguments: `-f` to clean up `kernel_out` before compiling and any other name of defconfig, e.g. `./build.sh k68v1_64_defconfig`, which will use `k68v1_64_defconfig` instead of default `pd1913f_defconfig`

Upon successful compilation, the compressed (`Image.gz`) and raw (`Image`) will be available at `kernel_out/arch/arm64/boot/`

### 2. Wrap the DTB

> Note: `wrap.py` was simplified since it was first written - it no longer needs a
> stock DTB as an input. The stock MTK LK header is captured directly in the script
> (only the size/offset fields actually vary per build), so it now only takes two
> arguments:
> ```bash
> python3 wrap.py <raw_dtb> <output_dtb.img>
> ```

### 3. Building against the android_device_vivo_1907N / LineageOS tree

If you're building this kernel to feed into the `device/vivo/1907N` LineageOS
tree (`BoardConfig.mk`'s `TARGET_PREBUILT_KERNEL`/`TARGET_PREBUILT_DTB` -
that tree does **not** build the kernel itself, it just consumes the
prebuilt `Image.gz` + `dtb.img` produced here), use `postbuild.sh` instead
of doing the DTB-wrap and file copy by hand:

```bash
./build.sh
./postbuild.sh
```

`postbuild.sh` wraps `kernel_out/arch/arm64/boot/dts/mediatek/mt6768.dtb`
via `wrap.py`, backs up whatever was previously in
`device/vivo/1907N/prebuilt/{Image.gz,dtb.img}` (suffixed
`.prev_<timestamp>.bak`), and installs the fresh pair there. It assumes
this kernel tree and the `lineage-19.1` tree are checked out as siblings
under the same parent directory - edit `DEVICE_PREBUILT_DIR` near the top
of the script if your layout differs. It only packages/copies files, it
never invokes `make`/`mka`/`m` itself - you still drive the actual
LineageOS rebuild (`mka bootimage` or a full build) and flashing yourself
afterwards.

### 4. Standalone boot.img repack (no AOSP tree, e.g. quick-testing a change)

To create a bootable `boot.img` directly instead, merge your custom build
with the stock image parameters:

#### 4.1. Unpack stock `boot.img`:
```bash
magiskboot unpack -n boot_stock.img
```

#### 4.2. Replace the DTB:
```bash
python3 wrap.py kernel_out/arch/arm64/boot/dts/mediatek/mt6768.dtb dtb
```
> Note: `magiskboot unpack` names the extracted DTB `dtb` by default -
> that's the output filename above, overwriting it in place.

#### 4.3. Repack the final image:
```bash
magiskboot repack -n boot_stock.img
```

> Note: The final image will be called `new-boot.img`

#### 4.4. Flash to device:
Flash `new-boot.img` via **fastboot** or using **custom recovery**:
```bash
fastboot flash boot new-boot.img
```

> Note: For flashing or backing up your device, you can use my [custom recovery](https://github.com/kavindren/android_device_vivo_1907N/releases/) for V17 Neo

---

## Contributing & Feedback
Contributions, bug reports, and feature requests are welcome!  
If you encounter any issues or want to improve the kernel:
- Open an **[Issue](https://github.com/kavindren/android_kernel_vivo_pd1913f/issues)** to report bugs or request features.
- Submit a **Pull Request (PR)** if you have fixes or enhancements to share.
