#!/usr/bin/env bash
# ==============================================================================
# SULTAN TOOLKIT - BUILD KERNEL SCRIPT
# ==============================================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

LANG_MODE="${CURRENT_LANG}"
TARGET=""
VARIANT=""
TEMP_ACTION="" # archive, clean, resume
CHECK_UPSTREAM="" # yes, no

usage() {
    cat <<EOF
Usage: $0 [options]

Options:
  -t, --target <gs201|zuma|zumapro>
                        Target Pixel device
  -v, --variant <ksu-susfs|ksu-susfs-vpnhide|ksu-next-susfs|ksu-next-susfs-vpnhide>
                        Kernel patch variant (Note: NoMount is included in all variants):
                          • ksu-susfs              (KernelSU + SusFS + NoMount)
                          • ksu-susfs-vpnhide      (KernelSU + SusFS + NoMount + VPNHide)
                          • ksu-next-susfs         (KernelSU-Next + SusFS + NoMount)
                          • ksu-next-susfs-vpnhide (KernelSU-Next + SusFS + NoMount + VPNHide)
  -a, --archive-temp    Archive existing ./temp to ./backup/kernel/ and prepare clean
  -c, --clean-temp      Clean existing ./temp without archiving
  -r, --resume          Resume build inside existing ./temp
      --check-upstream  Run upstream check before building
      --no-check-upstream Skip upstream check
  -l, --lang <en|ru>    Language (default: en)
  -h, --help            Show this help message
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -t|--target)
            TARGET="$2"
            shift 2
            ;;
        -v|--variant)
            VARIANT="$2"
            shift 2
            ;;
        -a|--archive-temp)
            TEMP_ACTION="archive"
            shift
            ;;
        -c|--clean-temp)
            TEMP_ACTION="clean"
            shift
            ;;
        -r|--resume)
            TEMP_ACTION="resume"
            shift
            ;;
        --check-upstream)
            CHECK_UPSTREAM="yes"
            shift
            ;;
        --no-check-upstream)
            CHECK_UPSTREAM="no"
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
check_toolchain || true
auto_install_dependencies

# 1. Check existing temp directory
if [[ -d "${TEMP_DIR}" && -n "$(ls -A "${TEMP_DIR}" 2>/dev/null)" ]]; then
    temp_size="$(du -sh "${TEMP_DIR}" 2>/dev/null | cut -f1)"
    if [[ -z "${TEMP_ACTION}" ]]; then
        if [[ "$LANG_MODE" == "ru" ]]; then
            echo -e "${C_YELLOW}Внимание: в папке ${C_BOLD}./temp${C_RESET}${C_YELLOW} уже есть файлы (размер: ${temp_size}).${C_RESET}"
            echo -e "Выберите действие:"
            echo -e "  ${C_BOLD}1)${C_RESET} Заархивировать в ./backup/kernel/ и подготовить чистый temp (Рекомендуется)"
            echo -e "  ${C_BOLD}2)${C_RESET} Очистить temp без архивации и начать с нуля"
            echo -e "  ${C_BOLD}3)${C_RESET} Продолжить сборку в текущем temp (без очистки)"
            echo -e "  ${C_BOLD}4)${C_RESET} Отмена"
            read -rp "$(echo -e "${C_CYAN}Ваш выбор [1-4] (по умолчанию 1): ${C_RESET}")" t_choice || true
        else
            echo -e "${C_YELLOW}Notice: ${C_BOLD}./temp${C_RESET}${C_YELLOW} contains existing build files (size: ${temp_size}).${C_RESET}"
            echo -e "Select action:"
            echo -e "  ${C_BOLD}1)${C_RESET} Archive to ./backup/kernel/ and prepare clean temp (Recommended)"
            echo -e "  ${C_BOLD}2)${C_RESET} Wipe temp without archiving"
            echo -e "  ${C_BOLD}3)${C_RESET} Continue build in existing temp (no wipe)"
            echo -e "  ${C_BOLD}4)${C_RESET} Cancel"
            read -rp "$(echo -e "${C_CYAN}Your choice [1-4] (default 1): ${C_RESET}")" t_choice || true
        fi
        t_choice="${t_choice:-1}"
        case "$t_choice" in
            1) TEMP_ACTION="archive" ;;
            2) TEMP_ACTION="clean" ;;
            3) TEMP_ACTION="resume" ;;
            *) echo "Cancelled."; exit 0 ;;
        esac
    fi

    if [[ "$TEMP_ACTION" == "archive" ]]; then
        archive_name="build_$(date +"%d.%m.%Y_%H-%M-%S").tar.gz"
        archive_path="${BACKUP_KERNEL}/${archive_name}"
        if [[ "$LANG_MODE" == "ru" ]]; then
            echo -e "\n${C_BLUE}==> Архивирую ./temp в ${archive_path}...${C_RESET}"
        else
            echo -e "\n${C_BLUE}==> Archiving ./temp to ${archive_path}...${C_RESET}"
        fi
        tar -czf "${archive_path}" -C "${ROOT_DIR}" temp
        if [[ "$LANG_MODE" == "ru" ]]; then
            echo -e "${C_GREEN}==> Архив сохранен ($(du -sh "${archive_path}" | cut -f1))!${C_RESET}"
            echo -e "${C_BLUE}==> Очищаю папку temp...${C_RESET}"
        else
            echo -e "${C_GREEN}==> Archive saved ($(du -sh "${archive_path}" | cut -f1))!${C_RESET}"
            echo -e "${C_BLUE}==> Cleaning temp directory...${C_RESET}"
        fi
        rm -rf "${TEMP_DIR}"
    elif [[ "$TEMP_ACTION" == "clean" ]]; then
        if [[ "$LANG_MODE" == "ru" ]]; then
            echo -e "\n${C_BLUE}==> Удаляю старое содержимое ./temp...${C_RESET}"
        else
            echo -e "\n${C_BLUE}==> Removing old contents of ./temp...${C_RESET}"
        fi
        rm -rf "${TEMP_DIR}"
    fi
fi

# 2. Copy clean source into temp if temp empty
if [[ ! -d "${TEMP_DIR}" || -z "$(ls -A "${TEMP_DIR}" 2>/dev/null)" ]]; then
    if [[ "$LANG_MODE" == "ru" ]]; then
        echo -e "\n${C_BLUE}==> Подготовка чистого дерева исходников в ./temp (Btrfs Copy-on-Write)...${C_RESET}"
    else
        echo -e "\n${C_BLUE}==> Preparing clean source tree in ./temp (Btrfs Copy-on-Write)...${C_RESET}"
    fi
    mkdir -p "${TEMP_DIR}"
    cp -a --reflink=auto "${SULTAN_SRC}/." "${TEMP_DIR}/"
    rm -f "${TEMP_DIR}"/*.zip 2>/dev/null || true
    if [[ "$LANG_MODE" == "ru" ]]; then
        echo -e "${C_GREEN}==> Чистое дерево готово в ./temp!${C_RESET}\n"
    else
        echo -e "${C_GREEN}==> Clean tree prepared in ./temp!${C_RESET}\n"
    fi
fi

# 3. Check upstream
if [[ -z "${CHECK_UPSTREAM}" ]]; then
    if [[ "$LANG_MODE" == "ru" ]]; then
        read -rp "$(echo -e "${C_CYAN}Проверить актуальность патчей upstream перед сборкой? [Y/n]: ${C_RESET}")" ans_up || true
    else
        read -rp "$(echo -e "${C_CYAN}Check upstream patch updates before building? [Y/n]: ${C_RESET}")" ans_up || true
    fi
    ans_up="${ans_up:-Y}"
    if [[ "$ans_up" =~ ^[YyДд]$ ]]; then
        CHECK_UPSTREAM="yes"
    else
        CHECK_UPSTREAM="no"
    fi
fi

if [[ "$CHECK_UPSTREAM" == "yes" ]]; then
    echo
    bash "${SCRIPT_DIR}/check_upstream.sh" --lang "${LANG_MODE}" || true
    echo
    if [[ -z "${TARGET}" || -z "${VARIANT}" ]]; then
        if [[ "$LANG_MODE" == "ru" ]]; then
            read -rp "$(echo -e "${C_CYAN}Продолжить сборку? [Y/n]: ${C_RESET}")" ans_cont || true
        else
            read -rp "$(echo -e "${C_CYAN}Continue build? [Y/n]: ${C_RESET}")" ans_cont || true
        fi
        ans_cont="${ans_cont:-Y}"
        if [[ ! "$ans_cont" =~ ^[YyДд]$ ]]; then
            echo "Cancelled."
            exit 0
        fi
    fi
fi

# 4. Target selection
if [[ -z "${TARGET}" ]]; then
    if [[ "$LANG_MODE" == "ru" ]]; then
        echo -e "\n${C_BOLD}${C_WHITE}Выберите целевое устройство (Target):${C_RESET}"
        echo -e "  ${C_BOLD}1)${C_RESET} ${C_GREEN}gs201${C_RESET}   • Google Pixel 7 / 7 Pro / 7a"
        echo -e "  ${C_BOLD}2)${C_RESET} ${C_GREEN}zuma${C_RESET}    • Google Pixel 8 / 8 Pro / 8a"
        echo -e "  ${C_BOLD}3)${C_RESET} ${C_GREEN}zumapro${C_RESET} • Google Pixel 9 / 9 Pro / 9 Pro XL / 9 Pro Fold"
        echo -e "  ${C_BOLD}0)${C_RESET} Отмена"
        read -rp "$(echo -e "${C_CYAN}Номер устройства [1-3]: ${C_RESET}")" dev_choice || true
    else
        echo -e "\n${C_BOLD}${C_WHITE}Select Target Device:${C_RESET}"
        echo -e "  ${C_BOLD}1)${C_RESET} ${C_GREEN}gs201${C_RESET}   • Google Pixel 7 / 7 Pro / 7a"
        echo -e "  ${C_BOLD}2)${C_RESET} ${C_GREEN}zuma${C_RESET}    • Google Pixel 8 / 8 Pro / 8a"
        echo -e "  ${C_BOLD}3)${C_RESET} ${C_GREEN}zumapro${C_RESET} • Google Pixel 9 / 9 Pro / 9 Pro XL / 9 Pro Fold"
        echo -e "  ${C_BOLD}0)${C_RESET} Cancel"
        read -rp "$(echo -e "${C_CYAN}Device number [1-3]: ${C_RESET}")" dev_choice || true
    fi

    case "${dev_choice:-0}" in
        1) TARGET="gs201" ;;
        2) TARGET="zuma" ;;
        3) TARGET="zumapro" ;;
        *) echo "Cancelled."; exit 0 ;;
    esac
fi

# 5. Variant selection (NoMount noted explicitly)
if [[ -z "${VARIANT}" ]]; then
    if [[ "$LANG_MODE" == "ru" ]]; then
        echo -e "\n${C_BOLD}${C_WHITE}Выберите вариант патчей ядра (NoMount включен во все):${C_RESET}"
        echo -e "  ${C_BOLD}1)${C_RESET} ${C_CYAN}ksu-susfs${C_RESET}              (KernelSU + SusFS + ${C_BOLD}NoMount${C_RESET})"
        echo -e "  ${C_BOLD}2)${C_RESET} ${C_CYAN}ksu-susfs-vpnhide${C_RESET}      (KernelSU + SusFS + ${C_BOLD}NoMount${C_RESET} + VPNHide)"
        echo -e "  ${C_BOLD}3)${C_RESET} ${C_CYAN}ksu-next-susfs${C_RESET}         (KernelSU-Next + SusFS + ${C_BOLD}NoMount${C_RESET})"
        echo -e "  ${C_BOLD}4)${C_RESET} ${C_CYAN}ksu-next-susfs-vpnhide${C_RESET} (KernelSU-Next + SusFS + ${C_BOLD}NoMount${C_RESET} + VPNHide)"
        echo -e "  ${C_BOLD}0)${C_RESET} Отмена"
        read -rp "$(echo -e "${C_CYAN}Номер варианта [1-4]: ${C_RESET}")" var_choice || true
    else
        echo -e "\n${C_BOLD}${C_WHITE}Select Kernel Patch Variant (NoMount is included in all):${C_RESET}"
        echo -e "  ${C_BOLD}1)${C_RESET} ${C_CYAN}ksu-susfs${C_RESET}              (KernelSU + SusFS + ${C_BOLD}NoMount${C_RESET})"
        echo -e "  ${C_BOLD}2)${C_RESET} ${C_CYAN}ksu-susfs-vpnhide${C_RESET}      (KernelSU + SusFS + ${C_BOLD}NoMount${C_RESET} + VPNHide)"
        echo -e "  ${C_BOLD}3)${C_RESET} ${C_CYAN}ksu-next-susfs${C_RESET}         (KernelSU-Next + SusFS + ${C_BOLD}NoMount${C_RESET})"
        echo -e "  ${C_BOLD}4)${C_RESET} ${C_CYAN}ksu-next-susfs-vpnhide${C_RESET} (KernelSU-Next + SusFS + ${C_BOLD}NoMount${C_RESET} + VPNHide)"
        echo -e "  ${C_BOLD}0)${C_RESET} Cancel"
        read -rp "$(echo -e "${C_CYAN}Variant number [1-4]: ${C_RESET}")" var_choice || true
    fi

    case "${var_choice:-0}" in
        1) VARIANT="ksu-susfs" ;;
        2) VARIANT="ksu-susfs-vpnhide" ;;
        3) VARIANT="ksu-next-susfs" ;;
        4) VARIANT="ksu-next-susfs-vpnhide" ;;
        *) echo "Cancelled."; exit 0 ;;
    esac
fi

# 6. Build Summary & Confirmation
echo -e "\n${C_CYAN}────────────────────────────────────────────────────────────────${C_RESET}"
if [[ "$LANG_MODE" == "ru" ]]; then
    echo -e "  ${C_BOLD}Конфигурация сборки:${C_RESET}"
    echo -e "  • Целевое устройство : ${C_BOLD}${C_GREEN}${TARGET}${C_RESET}"
    echo -e "  • Набор патчей       : ${C_BOLD}${C_CYAN}${VARIANT}${C_RESET} (+ NoMount)"
    echo -e "  • Рабочий каталог    : ${TEMP_DIR}"
    echo -e "  • AnyKernel каталог  : ${TEMP_DIR}/dist"
    echo -e "  • Каталог релизов    : ${RELEASE_DIR}"
else
    echo -e "  ${C_BOLD}Build Configuration:${C_RESET}"
    echo -e "  • Target Device      : ${C_BOLD}${C_GREEN}${TARGET}${C_RESET}"
    echo -e "  • Patch Variant      : ${C_BOLD}${C_CYAN}${VARIANT}${C_RESET} (+ NoMount)"
    echo -e "  • Working Directory  : ${TEMP_DIR}"
    echo -e "  • AnyKernel Out      : ${TEMP_DIR}/dist"
    echo -e "  • Release Directory  : ${RELEASE_DIR}"
fi
echo -e "${C_CYAN}────────────────────────────────────────────────────────────────${C_RESET}\n"

# Prompt confirmation if running interactively
if [[ -t 0 ]]; then
    if [[ "$LANG_MODE" == "ru" ]]; then
        read -rp "$(echo -e "${C_BOLD}${C_YELLOW}Запустить процесс сборки? [Y/n]: ${C_RESET}")" ans_build || true
    else
        read -rp "$(echo -e "${C_BOLD}${C_YELLOW}Start build process? [Y/n]: ${C_RESET}")" ans_build || true
    fi
    ans_build="${ans_build:-Y}"
    if [[ ! "$ans_build" =~ ^[YyДд]$ ]]; then
        echo "Cancelled."
        exit 0
    fi
fi

# 7. Execution
start_time="$(date +%s)"

echo -e "\n${C_BOLD}${C_GREEN}>>> [1/4] Applying patches: patch_sultan.sh ${TARGET} ${VARIANT}...${C_RESET}"
(
    cd "${TEMP_DIR}"
    bash ./gscripts/patch_sultan.sh "${TARGET}" "${VARIANT}"
) || {
    echo -e "\n${C_RED}ERROR: Patch step failed!${C_RESET}"
    exit 1
}

echo -e "\n${C_BOLD}${C_GREEN}>>> [2/4] Compiling kernel: build.sh ${TARGET}...${C_RESET}"
(
    cd "${TEMP_DIR}"
    bash ./gscripts/build.sh "${TARGET}"
) || {
    echo -e "\n${C_RED}ERROR: Kernel build failed!${C_RESET}"
    exit 1
}

echo -e "\n${C_BOLD}${C_GREEN}>>> [3/4] Packaging AnyKernel3: package.sh ${TARGET} ${VARIANT}...${C_RESET}"
(
    cd "${TEMP_DIR}"
    bash ./gscripts/package.sh "${TARGET}" "${VARIANT}"
) || {
    echo -e "\n${C_RED}ERROR: Packaging failed!${C_RESET}"
    exit 1
}

echo -e "\n${C_BOLD}${C_GREEN}>>> [4/4] Exporting artifacts to ./release/...${C_RESET}"
(
    cd "${TEMP_DIR}"
    if [[ -f "./gscripts/release-local.sh" ]]; then
        bash ./gscripts/release-local.sh "${TARGET}" "${VARIANT}"
    else
        mkdir -p "${RELEASE_DIR}"
        cp -v "${TEMP_DIR}/dist"/*.zip "${RELEASE_DIR}/"
    fi
)

end_time="$(date +%s)"
duration=$((end_time - start_time))
minutes=$((duration / 60))
seconds=$((duration % 60))

echo -e "\n${C_GREEN}╔══════════════════════════════════════════════════════════════════╗${C_RESET}"
if [[ "$LANG_MODE" == "ru" ]]; then
    echo -e "${C_GREEN}║${C_RESET}     ${C_BOLD}СБОРКА УСПЕШНО ЗАВЕРШЕНА! (${minutes}м ${seconds}с)${C_RESET}                         ${C_GREEN}║${C_RESET}"
else
    echo -e "${C_GREEN}║${C_RESET}     ${C_BOLD}BUILD SUCCESSFULLY COMPLETED! (${minutes}m ${seconds}s)${C_RESET}                    ${C_GREEN}║${C_RESET}"
fi
echo -e "${C_GREEN}╚══════════════════════════════════════════════════════════════════╝${C_RESET}"
echo -e "Output packages:"
ls -lh "${RELEASE_DIR}"/*.zip 2>/dev/null || true
echo -e "Release metadata: ${RELEASE_DIR}/nightly.json"
