# Sultan 17 Kernel Builder & Device Toolkit

[![Sultan 17](https://img.shields.io/badge/Sultan%2017-17.0.0--cp3a-green.svg)](https://github.com/gayclub731/SULTAN17-17.0.0-cp3a)
[![Kernel](https://img.shields.io/badge/Kernel-6.1%20GKI-blue.svg)](https://www.kernel.org/)
[![Devices](https://img.shields.io/badge/Pixel-gs201%20%7C%20zuma%20%7C%20zumapro-orange.svg)](https://store.google.com/)
[![License](https://img.shields.io/badge/License-GPLv2-lightgrey.svg)](sultan/COPYING)

Универсальный TUI и CLI-инструментарий для сборки кастомных ядер под Google Pixel (Pixel 7 / 8 / 9) с интеграцией патчей **Sultan**, **KSU**, **KSU-Next**, **SusFS**, **NoMount** и **VPNHide**, а также бэкапом разделов через ADB / Fastboot.

---

### Поддерживаемые устройства:
* **`gs201`** — Pixel 7 / 7 Pro / 7a (Tensor G2)
* **`zuma`** — Pixel 8 / 8 Pro / 8a (Tensor G3)
* **`zumapro`** — Pixel 9 / 9 Pro / 9 Pro XL / 9 Pro Fold (Tensor G4)

### Варианты ядер:
1. **`ksu-susfs`** — KernelSU + SusFS + **NoMount**
2. **`ksu-susfs-vpnhide`** — KernelSU + SusFS + **NoMount** + VPNHide
3. **`ksu-next-susfs`** — KernelSU-Next + SusFS + **NoMount**
4. **`ksu-next-susfs-vpnhide`** — KernelSU-Next + SusFS + **NoMount** + VPNHide

---

## Дерево каталогов

```text
SULTAN17-17.0.0-cp3a/
├── menu.sh               # Главное консольное TUI-меню (EN / RU)
├── scripts/              # Автономные скрипты с поддержкой CLI-флагов
│   ├── build_kernel.sh   # Сборка, патчинг и упаковка AnyKernel
│   ├── clean_temp.sh     # Очистка рабочей папки temp (с архивацией)
│   ├── backup_device.sh  # Дамп разделов смартфона через ADB / Fastboot
│   ├── check_upstream.sh # Проверка коммитов KSU, SusFS, NoMount, VPNHide
│   └── common.sh         # Общие переменные, пути и цвета
├── sultan/               # Чистый исходник ядра, тулчейн GCC 14.2 и gscripts
├── .github/workflows/    # Облачная сборка GitHub Actions (manual & nightly)
├── adb/                  # Google platform-tools (adb, fastboot v37.0.1)
├── release/              # Готовые AnyKernel zip и nightly.json
├── backup/               # Бэкапы разделов (android/) и сборок ядра (kernel/)
└── temp/                 # Изолированная папка сборки (CoW / reflink)
```

---

## Быстрый запуск (TUI)

```bash
./menu.sh
```

Либо клонирование и запуск в одну строчку:

```bash
git clone https://github.com/gayclub731/SULTAN17-17.0.0-cp3a.git && cd SULTAN17-17.0.0-cp3a && ./menu.sh
```
---

## Флаги (CLI)

### 1. Сборка ядра (`scripts/build_kernel.sh`)
```bash
# Пример: собрать Pixel 8 (zuma) с KSU-Next + SusFS + NoMount
./scripts/build_kernel.sh -t zuma -v ksu-next-susfs --clean-temp --no-check-upstream

# Флаги:
#  -t, --target <gs201|zuma|zumapro>                     Целевой девайс
#  -v, --variant <ksu-susfs|ksu-next-susfs|...-vpnhide>  Набор патчей
#  -a, --archive-temp                                    Архивировать старый temp в backup/
#  -c, --clean-temp                                      Очистить temp перед сборкой
#  -r, --resume                                          Продолжить в существующем temp
#      --check-upstream / --no-check-upstream            Проверка обновлений апстрима
#  -l, --lang <en|ru>                                    Язык вывода
```

### 2. Очистка temp (`scripts/clean_temp.sh`)
```bash
./scripts/clean_temp.sh --archive   # Архивировать в backup/kernel/ и удалить
./scripts/clean_temp.sh --force     # Быстрое удаление без лишних вопросов
```

### 3. Бэкап разделов телефона (`scripts/backup_device.sh`)
```bash
./scripts/backup_device.sh --all                # Дамп всех важных разделов (*)
./scripts/backup_device.sh -p "boot init_boot"  # Дамп выбранных разделов
./scripts/backup_device.sh --reboot-fastboot    # Авто-перевод в fastboot из adb

# Ключевые разделы (*):
#  * boot, init_boot (ядро, рамдиск KSU/Magisk), vendor_boot, vendor_kernel_boot,
#  * dtbo, vbmeta, vbmeta_system, vbmeta_vendor.
```

---

## 🤝 Благодарности (Credits)

* **[Ante0 / SULTAN17 (17.0.0-cp3a)](https://github.com/Ante0/SULTAN17/tree/17.0.0-cp3a)** — базовая ветка ядра Sultan под Pixel Tensor и скрипты сборки.
* **[Ante0 / android_kernel_google_tensynos (17.0.0-cp3a)](https://github.com/Ante0/android_kernel_google_tensynos/tree/17.0.0-cp3a)** — дерево ядра Google Tensor/Exynos.
* **[Sultan Alsawaf (kerneltoast)](https://github.com/kerneltoast)** — автор оригинального Sultan Kernel и оптимизаций.
* **[KernelSU (tiann)](https://github.com/tiann/KernelSU)** & **[KernelSU-Next](https://github.com/KernelSU-Next/KernelSU-Next)** — реализация root в пространстве ядра.
* **[SusFS (simonpunk)](https://gitlab.com/simonpunk/susfs4ksu)** — механизм скрытия рута и точек монтирования.
* **[NoMount (maxsteeel)](https://github.com/maxsteeel/nomount)** — драйвер скрытия mount namespaces.
* **[VPNHide (okhsunrog)](https://github.com/okhsunrog/vpnhide)** — драйвер скрытия интерфейса VPN.
* **[AnyKernel3 (osm0sis / Ante0)](https://github.com/Ante0/AnyKernel3)** — шаблон для прошивки ядер.
* **[Патчи Ante0](https://github.com/Ante0/kernel_patches)** & **[Фиксы Ante0](https://github.com/Ante0/fix_patches)** — набор патчей совместимости.
