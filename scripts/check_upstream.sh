#!/usr/bin/env bash
# ==============================================================================
# SULTAN TOOLKIT - CHECK UPSTREAM SCRIPT
# ==============================================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

LANG_MODE="${CURRENT_LANG}"

usage() {
    cat <<EOF
Usage: $0 [options]

Options:
  -l, --lang <en|ru>    Set language output (default: current or en)
  -h, --help            Show this help message
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
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

if [[ "$LANG_MODE" == "ru" ]]; then
    echo -e "${C_BOLD}${C_BLUE}===> Проверка обновлений Upstream (KSU, KSU-Next, SusFS, NoMount, VPNHide)...${C_RESET}"
else
    echo -e "${C_BOLD}${C_BLUE}===> Checking Upstream updates (KSU, KSU-Next, SusFS, NoMount, VPNHide)...${C_RESET}"
fi

check_script="${SULTAN_SRC}/gscripts/check-upstream.sh"
if [[ ! -f "${check_script}" ]]; then
    if [[ "$LANG_MODE" == "ru" ]]; then
        echo -e "${C_RED}Ошибка: скрипт check-upstream.sh не найден в ${SULTAN_SRC}/gscripts/${C_RESET}"
    else
        echo -e "${C_RED}Error: check-upstream.sh not found in ${SULTAN_SRC}/gscripts/${C_RESET}"
    fi
    exit 1
fi

tmp_out="$(mktemp)"
trap 'rm -f "$tmp_out"' EXIT

(
    cd "${SULTAN_SRC}"
    GITHUB_OUTPUT="${tmp_out}" bash "${check_script}"
) || {
    if [[ "$LANG_MODE" == "ru" ]]; then
        echo -e "${C_YELLOW}Предупреждение: проверка upstream завершилась с предупреждениями.${C_RESET}"
    else
        echo -e "${C_YELLOW}Warning: upstream check completed with warnings.${C_RESET}"
    fi
}

echo
if [[ "$LANG_MODE" == "ru" ]]; then
    echo -e "${C_GREEN}${C_BOLD}Текущие хэши upstream коммитов:${C_RESET}"
else
    echo -e "${C_GREEN}${C_BOLD}Current upstream commit SHAs:${C_RESET}"
fi

cache_shas="${ROOT_DIR}/.upstream_shas"
rm -f "${cache_shas}"

if [[ -f "${tmp_out}" ]]; then
    grep -E "_sha=" "${tmp_out}" | while IFS='=' read -r key val; do
        echo -e "  • ${C_BOLD}${key}${C_RESET}: ${val}"
        case "$key" in
            ksu_sha) echo "KSU_SHA=\"${val}\"" >> "${cache_shas}" ;;
            next_sha) echo "NEXT_SHA=\"${val}\"" >> "${cache_shas}" ;;
            susfs_sha) echo "SUSFS_SHA=\"${val}\"" >> "${cache_shas}" ;;
            nomount_sha) echo "NOMOUNT_SHA=\"${val}\"" >> "${cache_shas}" ;;
            vpnhide_sha) echo "VPNHIDE_SHA=\"${val}\"" >> "${cache_shas}" ;;
        esac
    done
fi
