# Credits & Acknowledgments

This project is built upon the incredible work of the Android kernel development and open-source community. Sincere gratitude is extended to all developers, contributors, and maintainers of the following upstream projects, repositories, patches, and tools:

---

## 1. Primary Upstream Repositories

* **[Ante0 / SULTAN17 (Branch: 17.0.0-cp3a)](https://github.com/Ante0/SULTAN17/tree/17.0.0-cp3a)**  
  The core base Sultan kernel tree, device configurations (`gs201`, `zuma`, `zumapro`), build scripts (`gscripts`), and GitHub Actions workflows tailored for Google Pixel Tensor devices on Android 15.

* **[Ante0 / android_kernel_google_tensynos (Branch: 17.0.0-cp3a)](https://github.com/Ante0/android_kernel_google_tensynos/tree/17.0.0-cp3a)**  
  Google Tensor / Exynos kernel tree and drivers for Tensor Pixel devices.

* **[Sultan Alsawaf (kerneltoast)](https://github.com/kerneltoast)**  
  Author and visionary of the original **Sultan Kernel**, renowned for exceptional kernel optimizations, battery life improvements, custom CPU/GPU governors, thermal throttling management, and smooth performance tweaks.

---

## 2. Root Implementations & Kernel Modules

* **[KernelSU by tiann](https://github.com/tiann/KernelSU)**  
  A kernel-based root solution for Android GKI devices, providing clean, permission-based root management in kernel space.

* **[KernelSU-Next by KernelSU-Next Team](https://github.com/KernelSU-Next/KernelSU-Next)**  
  An active, enhanced fork of KernelSU featuring additional features, extended compatibility hooks, and modern GKI support.

* **[SusFS for KernelSU by simonpunk](https://gitlab.com/simonpunk/susfs4ksu)**  
  Advanced kernel-level filesystem hiding mechanism designed specifically for KernelSU/KernelSU-Next to conceal root traces, mounts, and modifications.

* **[NoMount by maxsteeel](https://github.com/maxsteeel/nomount)**  
  Kernel driver and companion module to selectively hide mount namespaces and bypass root / mount detection. Included in all variants of this toolkit.

* **[VPNHide by okhsunrog](https://github.com/okhsunrog/vpnhide)**  
  Kernel-level network driver and routing hooks designed to conceal VPN interface state and prevent applications from detecting active VPN connections.

---

## 3. Patches & Kernel Compatibility Fixes

* **[Ante0 / kernel_patches](https://github.com/Ante0/kernel_patches)**  
  Collection of GKI, KernelSU, SusFS integration patches and compatibility fixes for Google Tensor devices.

* **[Ante0 / fix_patches](https://github.com/Ante0/fix_patches)**  
  Specific compatibility and build fixes for Sultan kernel source tree (`fs/namespace.c`, `kernel/sys.c`, `fs/super.c`).

---

## 4. Packaging, Flashing & Platform Tools

* **[AnyKernel3 by osm0sis](https://github.com/osm0sis/AnyKernel3) & [Ante0's AnyKernel3 fork](https://github.com/Ante0/AnyKernel3)**  
  The universal, flashable zip template for Android kernels, allowing seamless kernel flashing via custom recovery (TWRP/OrangeFox) or KernelSU/KernelFlasher without modifying rootfs partitions directly.

* **[Google Android Platform-Tools](https://developer.android.com/tools/releases/platform-tools)**  
  Official ADB and Fastboot utilities used for device partition dumping and bootloader management.

* **[GCC / Linaro / GNU Toolchain](https://gcc.gnu.org/)**  
  Standalone GCC 14.2.0 cross-compilation toolchain for aarch64 Linux.

---

*Thank you to all authors, contributors, and the entire Android development community for making open-source kernel customization possible!*
