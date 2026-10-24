# Sultan 17 Kernel Builder & Device Toolkit

[![Android 15](https://img.shields.io/badge/Android-15%20(cp3a)-green.svg)](https://android.googlesource.com/)
[![Kernel](https://img.shields.io/badge/Kernel-6.1%20GKI-blue.svg)](https://www.kernel.org/)
[![Devices](https://img.shields.io/badge/Pixel-Tensor%20gs201%20%7C%20zuma%20%7C%20zumapro-orange.svg)](https://store.google.com/)
[![License](https://img.shields.io/badge/License-GPLv2-lightgrey.svg)](COPYING)

An all-in-one console TUI and modular CLI toolkit for building **Sultan 17.0.0-cp3a** custom kernels for Google Pixel devices (Pixel 7 / 8 / 9 series), featuring integration with **KernelSU**, **KernelSU-Next**, **SusFS**, **NoMount**, and **VPNHide**, alongside an automated partition backup tool via ADB and Fastboot.

Works seamlessly **both locally on Linux** and **in the cloud via GitHub Actions CI/CD**.

---

## Supported Devices & Chips

| Target | Chipset | Supported Google Pixel Models | Defconfig |
| :--- | :--- | :--- | :--- |
| **`gs201`** | Google Tensor G2 | Pixel 7, Pixel 7 Pro, Pixel 7a | `gs201_defconfig` |
| **`zuma`** | Google Tensor G3 | Pixel 8, Pixel 8 Pro, Pixel 8a | `zuma_defconfig` |
| **`zumapro`** | Google Tensor G4 | Pixel 9, Pixel 9 Pro, Pixel 9 Pro XL, Pixel 9 Pro Fold | `zumapro_defconfig` |

---

## Kernel Patch Variants

> [!NOTE]
> **NoMount is included in all variants by default** to hide mount namespaces and bypass modern root checks.

| Variant | Components Included | Description |
| :--- | :--- | :--- |
| **`ksu-susfs`** | KernelSU + SusFS + **NoMount** | Standard official KernelSU with filesystem stealth (SusFS). |
| **`ksu-susfs-vpnhide`** | KernelSU + SusFS + **NoMount** + VPNHide | KernelSU and SusFS with kernel-level VPN detection bypass. |
| **`ksu-next-susfs`** | KernelSU-Next + SusFS + **NoMount** | Modern KernelSU-Next with SusFS integration and compatibility patches. |
| **`ksu-next-susfs-vpnhide`**| KernelSU-Next + SusFS + **NoMount** + VPNHide | Full suite: KernelSU-Next, SusFS, NoMount, and VPNHide. |

---

## Directory Structure

```text
SULTAN17-17.0.0-cp3a/
├── menu.sh                    # Main interactive Console TUI (English default, RU switchable)
├── scripts/                   # Standalone modular CLI scripts (can be called with flags)
│   ├── build_kernel.sh        # Kernel compilation, patching, and AnyKernel packaging
│   ├── clean_temp.sh          # Cleans working directory ./temp with optional archiving
│   ├── backup_device.sh       # Phone partition dumper via Fastboot fetch / Root ADB
│   ├── check_upstream.sh      # Upstream commit checker (GitHub/GitLab APIs)
│   └── common.sh              # Shared paths, environment, auto-recovery, and colors
├── sultan/                    # Pristine reference kernel source tree (with toolchains & gscripts)
│   ├── toolchains/            # GCC 14.2.0 cross-compiler (aarch64-linux-gnu)
│   ├── gscripts/              # Upstream Sultan build scripts & local release generator
│   └── arch/, fs/, ...        # Linux kernel 6.1 GKI source code
├── .github/workflows/         # Cloud CI/CD automation workflows
│   ├── build-manual.yml       # Manual trigger from GitHub UI (workflow_dispatch)
│   └── nightly.yml            # Scheduled nightly automated builds
├── adb/                       # Official Google Android platform-tools (adb, fastboot v37.0.1)
├── release/                   # Final AnyKernel3 zip packages & nightly.json metadata
├── backup/                    # Storage for device dumps & kernel build archives
│   ├── android/               # Extracted partition images (dd.mm.yyyy_HH-MM/)
│   └── kernel/                # Saved ./temp build archives (.tar.gz)
├── temp/                      # Dynamic build workspace (auto-created during compilation)
├── CREDITS.md                 # Full upstream attributions and repository links
└── README.md                  # Project documentation
```

---

## Quick Start (Interactive TUI)

Simply run the main menu in your terminal:

```bash
./menu.sh
```

### Features:
1. **[ 1 ] Build Kernel**: Select target device and patch variant, checks upstream updates, compiles in isolated `./temp`, and outputs flashable AnyKernel zip to `./release/`.
2. **[ 2 ] Clean ./temp Directory**: Safely wipes the build tree with an option to archive previous builds to `./backup/kernel/`.
3. **[ 3 ] Backup Device Partitions**: Scans for connected phones in ADB or Fastboot, detects the active slot (`_a` or `_b`), and dumps partitions.
4. **[ 4 ] Check Upstream Updates**: Fetches the latest commit SHAs for KernelSU, KernelSU-Next, SusFS, NoMount, and VPNHide.
5. **[ L ] Switch Language**: Toggles instantly between **English** and **Русский** (preference is remembered across runs).

---

## Command-Line Usage (Standalone CLI Scripts)

All scripts inside `scripts/` can be executed directly from shell or scripts without the interactive menu:

### 1. Kernel Compilation (`scripts/build_kernel.sh`)

```bash
# Build Pixel 8 (zuma) with KernelSU-Next, SusFS, and NoMount:
./scripts/build_kernel.sh --target zuma --variant ksu-next-susfs --clean-temp --no-check-upstream

# Build Pixel 7 (gs201) with VPNHide, archiving existing temp build first:
./scripts/build_kernel.sh -t gs201 -v ksu-next-susfs-vpnhide --archive-temp
```

**Options:**
* `-t, --target <gs201|zuma|zumapro>`: Select target Pixel device.
* `-v, --variant <ksu-susfs|ksu-susfs-vpnhide|ksu-next-susfs|ksu-next-susfs-vpnhide>`: Select patch bundle.
* `-a, --archive-temp`: Archive existing `./temp` to `./backup/kernel/` before preparing a clean workspace.
* `-c, --clean-temp`: Wipe existing `./temp` without archiving.
* `-r, --resume`: Resume build inside existing `./temp` without wiping.
* `--check-upstream`: Run upstream check before compiling.
* `--no-check-upstream`: Skip upstream check.
* `-l, --lang <en|ru>`: Language output (default: `en`).
* `-h, --help`: Display help.

---

### 2. Temp Cleaner (`scripts/clean_temp.sh`)

```bash
# Archive ./temp to backup/kernel/ and delete:
./scripts/clean_temp.sh --archive

# Force immediate wipe without prompting:
./scripts/clean_temp.sh --force
```

**Options:**
* `-a, --archive`: Archive `./temp` to `./backup/kernel/build_<date>.tar.gz` before deleting.
* `-f, --force`: Immediately delete `./temp` without archiving or asking confirmation.
* `-l, --lang <en|ru>`: Language output.

---

### 3. Device Partition Backup (`scripts/backup_device.sh`)

Uses the included standalone Google platform-tools (`./adb/adb` and `./adb/fastboot`).

```bash
# Dump all critical (*) partitions:
./scripts/backup_device.sh --all

# Dump specific partitions only:
./scripts/backup_device.sh --partitions "boot init_boot dtbo"

# Automatically reboot phone to bootloader if connected in ADB:
./scripts/backup_device.sh --all --reboot-fastboot
```

**Key partitions marked with `*`:**
* `* boot` (Kernel & primary ramdisk)
* `* init_boot` (Critical for Pixel on Android 13+! Houses Magisk / KernelSU ramdisk)
* `* vendor_boot` (Vendor ramdisk and drivers)
* `* vendor_kernel_boot` (Pixel kernel modules)
* `* dtbo` (Device Tree Blob)
* `* vbmeta`, `vbmeta_system`, `vbmeta_vendor` (AVB verification images)
* `pvmfw`, `misc`, `super` (Optional)

Dumps are stored in `./backup/android/<date>/` with an accompanying `backup_info.txt` containing serial, active slot, and SHA-256 checksums.

---

### 4. Upstream Checker (`scripts/check_upstream.sh`)

```bash
./scripts/check_upstream.sh
```
Fetches the latest commit SHAs from GitHub/GitLab and caches them into `.upstream_shas`.

---

## Running on GitHub Actions CI/CD

This repository includes two GitHub Actions workflows located in `.github/workflows/`:

1. **`Build Kernel (Manual)` (`build-manual.yml`)**:
   * Navigate to the **Actions** tab on your GitHub repository.
   * Select **Build Kernel (Manual)** and click **Run workflow**.
   * Choose your device target (`gs201`, `zuma`, `zumapro`, or `all`) and variant (`ksu-susfs`, `ksu-next-susfs`, etc.).
   * The build runs on Ubuntu runners and uploads the finished AnyKernel zip files directly to GitHub Artifacts.

2. **`Automated Nightly Build` (`nightly.yml`)**:
   * Runs on a daily schedule (`cron: "0 2 * * *"`) or manually.
   * Compiles the matrix and packages the latest builds.

---

## System Requirements & Host Dependencies

The cross-compilation toolchain (**GCC 14.2.0**) is already bundled inside `sultan/toolchains/`.

### Ubuntu / Debian:
```bash
sudo apt update && sudo apt install -y \
    bc bison build-essential curl flex git gh jq \
    libelf-dev libssl-dev lz4 pahole python3 rsync unzip zip
```

### Arch Linux / Manjaro:
```bash
sudo pacman -S --needed base-devel bc bison flex lz4 curl jq zip unzip python git github-cli
```

### Fedora:
```bash
sudo dnf install -y gcc make bc bison flex lz4 curl jq zip unzip python3 git gh elfutils-libelf-devel openssl-devel
```

---

## Credits & Acknowledgments

This project is built upon the work of Ante0, Sultan Alsawaf, tiann (KernelSU), KernelSU-Next team, simonpunk (SusFS), maxsteeel (NoMount), and okhsunrog (VPNHide).

For complete links, licenses, and detailed attributions, see **[CREDITS.md](CREDITS.md)**.

---

## License

The Linux kernel and patches are licensed under the **GNU General Public License v2 (GPL-2.0)**. See [COPYING](sultan/COPYING) for details.
