**English** | [Русский](README.md)

# Sultan 17 Kernel Builder & Device Toolkit

[![Sultan 17](https://img.shields.io/badge/Sultan%2017-17.0.0--cp3a-green.svg)](https://github.com/gayclub731/SULTAN17)
[![Kernel](https://img.shields.io/badge/Kernel-6.1%20GKI-blue.svg)](https://www.kernel.org/)
[![Devices](https://img.shields.io/badge/Pixel-gs201%20%7C%20zuma%20%7C%20zumapro-orange.svg)](https://store.google.com/)
[![License](https://img.shields.io/badge/License-GPLv2-lightgrey.svg)](sultan/COPYING)

A versatile TUI and CLI toolkit for building custom kernels for Google Pixel (Pixel 7 / 8 / 9) integrated with **Sultan**, **KSU**, **KSU-Next**, **SusFS**, **NoMount**, and **VPNHide** patches, along with partition dumping via ADB / Fastboot.

---

### Supported Devices:
* **`gs201`** — Pixel 7 / 7 Pro / 7a (Tensor G2)
* **`zuma`** — Pixel 8 / 8 Pro / 8a (Tensor G3)
* **`zumapro`** — Pixel 9 / 9 Pro / 9 Pro XL / 9 Pro Fold (Tensor G4)

### Kernel Variants:
1. **`ksu-susfs`** — KernelSU + SusFS + **NoMount**
2. **`ksu-susfs-vpnhide`** — KernelSU + SusFS + **NoMount** + VPNHide
3. **`ksu-next-susfs`** — KernelSU-Next + SusFS + **NoMount**
4. **`ksu-next-susfs-vpnhide`** — KernelSU-Next + SusFS + **NoMount** + VPNHide

---

## Directory Structure

```text
SULTAN17/
├── menu.sh               # Main interactive TUI console menu (EN / RU)
├── scripts/              # Standalone CLI scripts with flag support
│   ├── build_kernel.sh   # Build, patch, and pack AnyKernel3 zip
│   ├── clean_temp.sh     # Clean working temp directory (with archiving)
│   ├── backup_device.sh  # Dump device partitions via ADB / Fastboot
│   ├── check_upstream.sh # Check commit updates for KSU, SusFS, NoMount, VPNHide
│   └── common.sh         # Shared environment, paths, and colors
├── sultan/               # Pristine kernel source, GCC 14.2 toolchain, and gscripts
├── .github/workflows/    # Cloud GitHub Actions workflows (manual & nightly)
├── adb/                  # Official Google platform-tools (adb, fastboot v37.0.1)
├── release/              # Ready AnyKernel3 zip files and nightly.json metadata
├── backup/               # Partition dumps (android/) and temp archives (kernel/)
└── temp/                 # Isolated build directory (Btrfs CoW / reflink fallback)
```

---

## Quick Start (Interactive TUI)

Run the console menu directly in your terminal:

```bash
./menu.sh
```

Or clone and launch in a single command:
```bash
git clone -b 17.0.0-cp3a https://github.com/gayclub731/SULTAN17.git && cd SULTAN17 && ./menu.sh
```

---

## CLI Flags

### 1. Build Kernel (`scripts/build_kernel.sh`)
```bash
# Example: build Pixel 8 (zuma) with KSU-Next + SusFS + NoMount
./scripts/build_kernel.sh -t zuma -v ksu-next-susfs --clean-temp --no-check-upstream

# Options:
#  -t, --target <gs201|zuma|zumapro>                     Target device
#  -v, --variant <ksu-susfs|ksu-next-susfs|...-vpnhide>  Patch variant
#  -a, --archive-temp                                    Archive old temp to backup/
#  -c, --clean-temp                                      Wipe temp before building
#  -r, --resume                                          Continue build inside existing temp
#      --check-upstream / --no-check-upstream            Check upstream updates
#  -l, --lang <en|ru>                                    Output language
```

### 2. Clean Temp (`scripts/clean_temp.sh`)
```bash
./scripts/clean_temp.sh --archive   # Archive to backup/kernel/ and remove
./scripts/clean_temp.sh --force     # Fast delete without confirmation
```

### 3. Backup Phone Partitions (`scripts/backup_device.sh`)
```bash
./scripts/backup_device.sh --all                # Dump all critical partitions (*)
./scripts/backup_device.sh -p "boot init_boot"  # Dump selected partitions
./scripts/backup_device.sh --reboot-fastboot    # Automatically reboot from ADB to Fastboot

# Critical partitions (*):
#  * boot, init_boot (kernel, KSU/Magisk ramdisk), vendor_boot, vendor_kernel_boot,
#  * dtbo, vbmeta, vbmeta_system, vbmeta_vendor.
```

---

## Credits

* **[gayclub731](https://github.com/gayclub731)**
