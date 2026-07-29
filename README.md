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
- **In progress (Known issues):**
  - [ ] **Fingerprint**
  - [ ] **NFC**
  - [ ] **Light sensor**
  - [ ] **Camera**
  - [ ] **vivo Fast Charge**

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

### 2. Prepare the Image & DTB
To create a bootable `boot.img`, merge your custom build with the stock image parameters:

### 2.1. Unpack stock `boot.img`:
```bash
magiskboot unpack -n boot_stock.img
```

### 2.2. Merge Device Tree Blob (DTB):
Run the `wrap.py` helper script to combine the stock DTB and your freshly built DTB:
```bash
python3 wrap.py stock_dtb kernel_out/arch/arm64/boot/dts/mediatek/mt6768.dtb dtb
```

> Note: The unpacked DTB from `boot_stock.img` is called `dtb` by default. Rename it to `stock_dtb` if you want to.

### 3. Repack & Flash

### 3.1. Repack the final image:
```bash
magiskboot repack -n boot_stock.img
```

> Note: The final image will be called `new-boot.img`

### 3.2. Flash to device:
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
