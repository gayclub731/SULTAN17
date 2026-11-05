#!/usr/bin/env bash
# ==============================================================================
# SULTAN TOOLKIT - BACKUP DEVICE PARTITIONS SCRIPT
# ==============================================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

LANG_MODE="${CURRENT_LANG}"
DO_ALL=false
AUTO_REBOOT_FB=false
CLI_PARTS=""

usage() {
    cat <<EOF
Usage: $0 [options]

Options:
  -a, --all               Backup all recommended (*) partitions
  -p, --partitions "..."  Space-separated list of partition names to dump
      --reboot-fastboot   Automatically reboot to bootloader if connected via ADB
  -l, --lang <en|ru>      Language (default: en)
  -h, --help              Show this help message
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--all)
            DO_ALL=true
            shift
            ;;
        -p|--partitions)
            CLI_PARTS="$2"
            shift 2
            ;;
        --reboot-fastboot)
            AUTO_REBOOT_FB=true
            shift
            ;;
        -l|--lang)
            LANG_MODE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

ensure_base_dirs
check_platform_tools

if [[ "$LANG_MODE" == "ru" ]]; then
    echo -e "${C_BLUE}==> Поиск подключенных устройств через platform-tools...${C_RESET}"
else
    echo -e "${C_BLUE}==> Searching for connected devices via platform-tools...${C_RESET}"
fi

adb_devs="$("${ADB_BIN}" devices | grep -v "List of devices" | grep "device$" || true)"
fb_devs="$("${FASTBOOT_BIN}" devices 2>&1 | grep "fastboot$" || true)"

mode="none"
dev_serial=""

if [[ -n "${fb_devs}" ]]; then
    mode="fastboot"
    dev_serial="$(echo "${fb_devs}" | head -n1 | awk '{print $1}')"
elif [[ -n "${adb_devs}" ]]; then
    mode="adb"
    dev_serial="$(echo "${adb_devs}" | head -n1 | awk '{print $1}')"
fi

if [[ "$mode" == "none" ]]; then
    if [[ "$LANG_MODE" == "ru" ]]; then
        echo -e "${C_RED}Устройства не найдены!${C_RESET}"
        echo -e "\n${C_YELLOW}Подсказка:${C_RESET}"
        echo -e "  • Для работы по ADB: включите 'Отладка по USB' на смартфоне и подтвердите запрос на экране."
        echo -e "  • Для работы по Fastboot: выключите смартфон и зажмите [Громкость Вниз + Питание]."
    else
        echo -e "${C_RED}No devices found!${C_RESET}"
        echo -e "\n${C_YELLOW}Tip:${C_RESET}"
        echo -e "  • For ADB: enable 'USB Debugging' in developer options and authorize on phone screen."
        echo -e "  • For Fastboot: power off phone and hold [Volume Down + Power]."
    fi
    exit 1
fi

if [[ "$LANG_MODE" == "ru" ]]; then
    echo -e "${C_GREEN}Обнаружено устройство: ${C_BOLD}${dev_serial}${C_RESET} [Режим: ${C_BOLD}${mode^^}${C_RESET}]\n"
else
    echo -e "${C_GREEN}Device detected: ${C_BOLD}${dev_serial}${C_RESET} [Mode: ${C_BOLD}${mode^^}${C_RESET}]\n"
fi

# ADB Handling
if [[ "$mode" == "adb" ]]; then
    model="$("${ADB_BIN}" shell getprop ro.product.model 2>/dev/null | tr -d '\r' || echo 'Unknown')"
    device_name="$("${ADB_BIN}" shell getprop ro.product.device 2>/dev/null | tr -d '\r' || echo 'Unknown')"
    android_ver="$("${ADB_BIN}" shell getprop ro.build.version.release 2>/dev/null | tr -d '\r' || echo 'Unknown')"
    has_root="$("${ADB_BIN}" shell "su -c id" 2>/dev/null | grep "uid=0" || true)"

    if [[ "$LANG_MODE" == "ru" ]]; then
        echo -e "  • Модель     : ${C_BOLD}${model} (${device_name})${C_RESET}"
        echo -e "  • Android    : ${C_BOLD}${android_ver}${C_RESET}"
        echo -e "  • Root (su)  : $([[ -n "$has_root" ]] && echo -e "${C_GREEN}Доступен${C_RESET}" || echo -e "${C_YELLOW}Не найден${C_RESET}")"
    else
        echo -e "  • Model      : ${C_BOLD}${model} (${device_name})${C_RESET}"
        echo -e "  • Android    : ${C_BOLD}${android_ver}${C_RESET}"
        echo -e "  • Root (su)  : $([[ -n "$has_root" ]] && echo -e "${C_GREEN}Available${C_RESET}" || echo -e "${C_YELLOW}Not found${C_RESET}")"
    fi
    echo

    need_reboot_fb=false
    if [[ "$AUTO_REBOOT_FB" == "true" ]]; then
        need_reboot_fb=true
    elif [[ -z "$has_root" ]]; then
        need_reboot_fb=true
    else
        # Interactive prompt if root is available
        if [[ "$LANG_MODE" == "ru" ]]; then
            echo -e "Выберите способ бэкапа:"
            echo -e "  ${C_BOLD}1)${C_RESET} Перезагрузить в ${C_CYAN}Fastboot${C_RESET} (Рекомендуется)"
            echo -e "  ${C_BOLD}2)${C_RESET} Снять дамп прямо сейчас через ${C_GREEN}Root ADB (dd)${C_RESET}"
            read -rp "$(echo -e "${C_CYAN}Ваш выбор [1-2] (по умолчанию 1): ${C_RESET}")" adb_action || true
        else
            echo -e "Choose backup method:"
            echo -e "  ${C_BOLD}1)${C_RESET} Reboot to ${C_CYAN}Fastboot${C_RESET} (Recommended)"
            echo -e "  ${C_BOLD}2)${C_RESET} Dump partitions live via ${C_GREEN}Root ADB (dd)${C_RESET}"
            read -rp "$(echo -e "${C_CYAN}Your choice [1-2] (default 1): ${C_RESET}")" adb_action || true
        fi
        adb_action="${adb_action:-1}"
        if [[ "$adb_action" == "1" ]]; then
            need_reboot_fb=true
        fi
    fi

    if [[ "$need_reboot_fb" == "true" ]]; then
        if [[ "$LANG_MODE" == "ru" ]]; then
            echo -e "\n${C_BLUE}==> Перезагружаю устройство в бутлоадер (adb reboot bootloader)...${C_RESET}"
            echo -e "Ожидание появления устройства в режиме Fastboot..."
        else
            echo -e "\n${C_BLUE}==> Rebooting device to bootloader (adb reboot bootloader)...${C_RESET}"
            echo -e "Waiting for device in Fastboot mode..."
        fi
        "${ADB_BIN}" reboot bootloader
        waited=0
        while [[ $waited -lt 30 ]]; do
            sleep 2
            waited=$((waited + 2))
            fb_devs="$("${FASTBOOT_BIN}" devices 2>&1 | grep "fastboot$" || true)"
            if [[ -n "${fb_devs}" ]]; then
                mode="fastboot"
                dev_serial="$(echo "${fb_devs}" | head -n1 | awk '{print $1}')"
                if [[ "$LANG_MODE" == "ru" ]]; then
                    echo -e "${C_GREEN}Устройство подключено в режиме Fastboot (${dev_serial})!${C_RESET}\n"
                else
                    echo -e "${C_GREEN}Device connected in Fastboot mode (${dev_serial})!${C_RESET}\n"
                fi
                break
            fi
        done
        if [[ "$mode" != "fastboot" ]]; then
            if [[ "$LANG_MODE" == "ru" ]]; then
                echo -e "${C_RED}Таймаут ожидания fastboot. Проверьте кабель.${C_RESET}"
            else
                echo -e "${C_RED}Timed out waiting for fastboot. Check cable connection.${C_RESET}"
            fi
            exit 1
        fi
    fi
fi

# Fastboot Details
current_slot="a"
is_unlocked="unknown"
product="unknown"

if [[ "$mode" == "fastboot" ]]; then
    current_slot="$("${FASTBOOT_BIN}" getvar current-slot 2>&1 | grep "current-slot:" | awk '{print $2}' | tr -d '\r' || echo 'a')"
    current_slot="${current_slot:-a}"
    is_unlocked="$("${FASTBOOT_BIN}" getvar unlocked 2>&1 | grep "unlocked:" | awk '{print $2}' | tr -d '\r' || echo 'unknown')"
    product="$("${FASTBOOT_BIN}" getvar product 2>&1 | grep "product:" | awk '{print $2}' | tr -d '\r' || echo 'unknown')"

    if [[ "$LANG_MODE" == "ru" ]]; then
        echo -e "  • Девайс       : ${C_BOLD}${product}${C_RESET}"
        echo -e "  • Активный слот: ${C_BOLD}_${current_slot}${C_RESET}"
        echo -e "  • Bootloader   : ${C_BOLD}$([[ "$is_unlocked" == "yes" ]] && echo -e "${C_GREEN}Разблокирован (unlocked)${C_RESET}" || echo -e "${C_YELLOW}${is_unlocked}${C_RESET}")${C_RESET}"
    else
        echo -e "  • Device       : ${C_BOLD}${product}${C_RESET}"
        echo -e "  • Active slot  : ${C_BOLD}_${current_slot}${C_RESET}"
        echo -e "  • Bootloader   : ${C_BOLD}$([[ "$is_unlocked" == "yes" ]] && echo -e "${C_GREEN}Unlocked${C_RESET}" || echo -e "${C_YELLOW}${is_unlocked}${C_RESET}")${C_RESET}"
    fi
    echo
fi

# Determine partitions
partitions_to_dump=()

if [[ "$DO_ALL" == "true" ]]; then
    partitions_to_dump=("boot" "init_boot" "vendor_boot" "vendor_kernel_boot" "dtbo" "vbmeta" "vbmeta_system" "vbmeta_vendor")
elif [[ -n "$CLI_PARTS" ]]; then
    read -ra partitions_to_dump <<< "$CLI_PARTS"
else
    # Interactive menu
    if [[ "$LANG_MODE" == "ru" ]]; then
        echo -e "${C_BOLD}${C_WHITE}Список разделов для бэкапа (* отмечены ключевые):${C_RESET}"
        echo -e "  ${C_GREEN}* 1)${C_RESET} ${C_BOLD}boot${C_RESET}               (Ядро и базовый ramdisk)"
        echo -e "  ${C_GREEN}* 2)${C_RESET} ${C_BOLD}init_boot${C_RESET}          (Критично для Pixel! Magisk / KernelSU)"
        echo -e "  ${C_GREEN}* 3)${C_RESET} ${C_BOLD}vendor_boot${C_RESET}        (Драйверы и рамдиск вендора)"
        echo -e "  ${C_GREEN}* 4)${C_RESET} ${C_BOLD}vendor_kernel_boot${C_RESET} (Модули ядра)"
        echo -e "  ${C_GREEN}* 5)${C_RESET} ${C_BOLD}dtbo${C_RESET}               (Device Tree Blob)"
        echo -e "  ${C_GREEN}* 6)${C_RESET} ${C_BOLD}vbmeta${C_RESET}             (AVB проверка верификации)"
        echo -e "  ${C_GREEN}* 7)${C_RESET} ${C_BOLD}vbmeta_system${C_RESET}      (AVB образ system)"
        echo -e "  ${C_GREEN}* 8)${C_RESET} ${C_BOLD}vbmeta_vendor${C_RESET}      (AVB образ vendor)"
        echo -e "    9) pvmfw              (Виртуализация pKVM)"
        echo -e "   10) misc               (Параметры bootloader)"
        echo -e "   11) super              ${C_YELLOW}(Внимание: системные разделы, размер 8-12 ГБ!)${C_RESET}"
        echo -e "  ${C_BOLD}${C_CYAN} [A] Сделать бэкап ВСЕХ важных (*) разделов [1-8] (Рекомендуется)${C_RESET}"
        echo -e "   [C] Ввести имя раздела вручную"
        echo -e "   [0] Отмена"
        echo
        read -rp "$(echo -e "${C_CYAN}Выберите разделы (например: A или 1 2 4): ${C_RESET}")" part_select || true
    else
        echo -e "${C_BOLD}${C_WHITE}Partition backup list (* marks critical partitions):${C_RESET}"
        echo -e "  ${C_GREEN}* 1)${C_RESET} ${C_BOLD}boot${C_RESET}               (Kernel & base ramdisk)"
        echo -e "  ${C_GREEN}* 2)${C_RESET} ${C_BOLD}init_boot${C_RESET}          (Critical for Pixel! Magisk / KernelSU)"
        echo -e "  ${C_GREEN}* 3)${C_RESET} ${C_BOLD}vendor_boot${C_RESET}        (Vendor ramdisk & modules)"
        echo -e "  ${C_GREEN}* 4)${C_RESET} ${C_BOLD}vendor_kernel_boot${C_RESET} (Kernel modules)"
        echo -e "  ${C_GREEN}* 5)${C_RESET} ${C_BOLD}dtbo${C_RESET}               (Device Tree Blob)"
        echo -e "  ${C_GREEN}* 6)${C_RESET} ${C_BOLD}vbmeta${C_RESET}             (AVB verification)"
        echo -e "  ${C_GREEN}* 7)${C_RESET} ${C_BOLD}vbmeta_system${C_RESET}      (AVB system image)"
        echo -e "  ${C_GREEN}* 8)${C_RESET} ${C_BOLD}vbmeta_vendor${C_RESET}      (AVB vendor image)"
        echo -e "    9) pvmfw              (pKVM virtualization)"
        echo -e "   10) misc               (Bootloader parameters)"
        echo -e "   11) super              ${C_YELLOW}(Warning: system image, 8-12 GB!)${C_RESET}"
        echo -e "  ${C_BOLD}${C_CYAN} [A] Backup ALL important (*) partitions [1-8] (Recommended)${C_RESET}"
        echo -e "   [C] Enter custom partition name"
        echo -e "   [0] Cancel"
        echo
        read -rp "$(echo -e "${C_CYAN}Select partitions (e.g. A or 1 2 4): ${C_RESET}")" part_select || true
    fi
    part_select="${part_select:-A}"

    if [[ "$part_select" =~ ^[AaФф]$ ]]; then
        partitions_to_dump=("boot" "init_boot" "vendor_boot" "vendor_kernel_boot" "dtbo" "vbmeta" "vbmeta_system" "vbmeta_vendor")
    elif [[ "$part_select" =~ ^[CcСс]$ ]]; then
        read -rp "Enter exact partition name: " custom_part || true
        if [[ -n "$custom_part" ]]; then
            partitions_to_dump=("$custom_part")
        fi
    elif [[ "$part_select" =~ ^[0Qq]$ ]]; then
        echo "Cancelled."
        exit 0
    else
        for num in $part_select; do
            case "$num" in
                1) partitions_to_dump+=("boot") ;;
                2) partitions_to_dump+=("init_boot") ;;
                3) partitions_to_dump+=("vendor_boot") ;;
                4) partitions_to_dump+=("vendor_kernel_boot") ;;
                5) partitions_to_dump+=("dtbo") ;;
                6) partitions_to_dump+=("vbmeta") ;;
                7) partitions_to_dump+=("vbmeta_system") ;;
                8) partitions_to_dump+=("vbmeta_vendor") ;;
                9) partitions_to_dump+=("pvmfw") ;;
                10) partitions_to_dump+=("misc") ;;
                11) partitions_to_dump+=("super") ;;
            esac
        done
    fi
fi

if (( ${#partitions_to_dump[@]} == 0 )); then
    if [[ "$LANG_MODE" == "ru" ]]; then
        echo -e "${C_RED}Разделы не выбраны.${C_RESET}"
    else
        echo -e "${C_RED}No partitions selected.${C_RESET}"
    fi
    exit 1
fi

date_dir="$(date +"%d.%m.%Y_%H-%M-%S")"
backup_target="${BACKUP_ANDROID}/${date_dir}"
mkdir -p "${backup_target}"

if [[ "$LANG_MODE" == "ru" ]]; then
    echo -e "\n${C_GREEN}==> Запуск процесса бэкапа в каталог:${C_RESET} ${backup_target}\n"
else
    echo -e "\n${C_GREEN}==> Starting backup process to directory:${C_RESET} ${backup_target}\n"
fi

success_count=0
fail_count=0

for base_part in "${partitions_to_dump[@]}"; do
    out_file="${backup_target}/${base_part}.img"

    if [[ "$mode" == "fastboot" ]]; then
        slot_part="${base_part}_${current_slot}"
        echo -ne "  • Dump ${C_BOLD}${slot_part}${C_RESET}... "
        if "${FASTBOOT_BIN}" fetch "${slot_part}" "${backup_target}/${slot_part}.img" 2>/dev/null; then
            fsize="$(du -sh "${backup_target}/${slot_part}.img" | cut -f1)"
            echo -e "${C_GREEN}[ OK ] (${fsize})${C_RESET}"
            success_count=$((success_count + 1))
            continue
        fi

        echo -ne "\r  • Dump ${C_BOLD}${base_part}${C_RESET} (no slot)... "
        if "${FASTBOOT_BIN}" fetch "${base_part}" "${out_file}" 2>/dev/null; then
            fsize="$(du -sh "${out_file}" | cut -f1)"
            echo -e "${C_GREEN}[ OK ] (${fsize})${C_RESET}"
            success_count=$((success_count + 1))
        else
            echo -e "${C_RED}[ FAILED ]${C_RESET} (bootloader denied fetch)"
            fail_count=$((fail_count + 1))
        fi
    else
        slot_part="${base_part}_${current_slot}"
        echo -ne "  • Dump ${C_BOLD}${slot_part}${C_RESET} via dd... "
        dev_node="/dev/block/by-name/${slot_part}"
        if ! "${ADB_BIN}" shell "su -c 'test -b ${dev_node}'" 2>/dev/null; then
            dev_node="/dev/block/by-name/${base_part}"
            slot_part="${base_part}"
        fi

        if "${ADB_BIN}" exec-out "su -c 'dd if=${dev_node} 2>/dev/null'" > "${backup_target}/${slot_part}.img" && [[ -s "${backup_target}/${slot_part}.img" ]]; then
            fsize="$(du -sh "${backup_target}/${slot_part}.img" | cut -f1)"
            echo -e "${C_GREEN}[ OK ] (${fsize})${C_RESET}"
            success_count=$((success_count + 1))
        else
            echo -e "${C_RED}[ FAILED ]${C_RESET}"
            rm -f "${backup_target}/${slot_part}.img"
            fail_count=$((fail_count + 1))
        fi
    fi
done

cat > "${backup_target}/backup_info.txt" <<EOF
Backup Date     : $(date +"%Y-%m-%d %H:%M:%S")
Mode            : ${mode^^}
Device Serial   : ${dev_serial}
Active Slot     : _${current_slot}
Success Dumps   : ${success_count}
Failures        : ${fail_count}

Files:
$(ls -lh "${backup_target}"/*.img 2>/dev/null || echo 'No images')
EOF

if [[ "$LANG_MODE" == "ru" ]]; then
    echo -e "\n${C_GREEN}==> Бэкап завершен!${C_RESET}"
    echo -e "Успешно: ${C_BOLD}${success_count}${C_RESET}, Ошибок: ${C_BOLD}${fail_count}${C_RESET}"
    echo -e "Каталог: ${C_BOLD}${backup_target}${C_RESET}"
else
    echo -e "\n${C_GREEN}==> Backup completed!${C_RESET}"
    echo -e "Successful: ${C_BOLD}${success_count}${C_RESET}, Failures: ${C_BOLD}${fail_count}${C_RESET}"
    echo -e "Directory : ${C_BOLD}${backup_target}${C_RESET}"
fi
