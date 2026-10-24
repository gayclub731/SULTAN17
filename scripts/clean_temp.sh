#!/usr/bin/env bash
# ==============================================================================
# SULTAN TOOLKIT - CLEAN TEMP SCRIPT
# ==============================================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

LANG_MODE="${CURRENT_LANG}"
DO_ARCHIVE=false
DO_FORCE=false

usage() {
    cat <<EOF
Usage: $0 [options]

Options:
  -a, --archive         Archive ./temp to ./backup/kernel/ before deleting
  -f, --force           Delete ./temp without archiving or prompting
  -l, --lang <en|ru>    Language (default: en)
  -h, --help            Show this help message
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -a|--archive)
            DO_ARCHIVE=true
            shift
            ;;
        -f|--force)
            DO_FORCE=true
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

if [[ ! -d "${TEMP_DIR}" || -z "$(ls -A "${TEMP_DIR}" 2>/dev/null)" ]]; then
    if [[ "$LANG_MODE" == "ru" ]]; then
        echo -e "${C_GREEN}Папка ./temp уже пуста или не существует.${C_RESET}"
    else
        echo -e "${C_GREEN}Directory ./temp is already empty or does not exist.${C_RESET}"
    fi
    exit 0
fi

temp_size="$(du -sh "${TEMP_DIR}" 2>/dev/null | cut -f1)"

if [[ "$DO_ARCHIVE" == "true" ]]; then
    archive_name="build_$(date +"%d.%m.%Y_%H-%M-%S").tar.gz"
    archive_path="${BACKUP_KERNEL}/${archive_name}"
    if [[ "$LANG_MODE" == "ru" ]]; then
        echo -e "${C_BLUE}==> Архивирую ./temp в ${archive_path}...${C_RESET}"
    else
        echo -e "${C_BLUE}==> Archiving ./temp to ${archive_path}...${C_RESET}"
    fi
    tar -czf "${archive_path}" -C "${ROOT_DIR}" temp
    if [[ "$LANG_MODE" == "ru" ]]; then
        echo -e "${C_GREEN}==> Архив сохранен: ${archive_path} ($(du -sh "${archive_path}" | cut -f1))${C_RESET}"
        echo -e "${C_BLUE}==> Удаляю папку ./temp...${C_RESET}"
    else
        echo -e "${C_GREEN}==> Archive saved: ${archive_path} ($(du -sh "${archive_path}" | cut -f1))${C_RESET}"
        echo -e "${C_BLUE}==> Removing ./temp directory...${C_RESET}"
    fi
    rm -rf "${TEMP_DIR}"
    if [[ "$LANG_MODE" == "ru" ]]; then
        echo -e "${C_GREEN}==> Папка ./temp успешно очищена!${C_RESET}"
    else
        echo -e "${C_GREEN}==> Directory ./temp successfully cleaned!${C_RESET}"
    fi
    exit 0
fi

if [[ "$DO_FORCE" == "true" ]]; then
    if [[ "$LANG_MODE" == "ru" ]]; then
        echo -e "${C_BLUE}==> Удаляю папку ./temp...${C_RESET}"
    else
        echo -e "${C_BLUE}==> Removing ./temp directory...${C_RESET}"
    fi
    rm -rf "${TEMP_DIR}"
    if [[ "$LANG_MODE" == "ru" ]]; then
        echo -e "${C_GREEN}==> Папка ./temp успешно удалена!${C_RESET}"
    else
        echo -e "${C_GREEN}==> Directory ./temp successfully removed!${C_RESET}"
    fi
    exit 0
fi

# Interactive mode
if [[ "$LANG_MODE" == "ru" ]]; then
    echo -e "Текущий размер папки ${C_BOLD}./temp${C_RESET}: ${C_BOLD}${C_YELLOW}${temp_size}${C_RESET}"
    echo -e "Выберите действие:"
    echo -e "  ${C_BOLD}1)${C_RESET} Заархивировать в ./backup/kernel/ и удалить (Рекомендуется)"
    echo -e "  ${C_BOLD}2)${C_RESET} Удалить сразу без архивации"
    echo -e "  ${C_BOLD}3)${C_RESET} Отмена"
    echo
    read -rp "$(echo -e "${C_CYAN}Ваш выбор [1-3]: ${C_RESET}")" choice || true
else
    echo -e "Current size of ${C_BOLD}./temp${C_RESET}: ${C_BOLD}${C_YELLOW}${temp_size}${C_RESET}"
    echo -e "Select action:"
    echo -e "  ${C_BOLD}1)${C_RESET} Archive to ./backup/kernel/ and remove (Recommended)"
    echo -e "  ${C_BOLD}2)${C_RESET} Remove immediately without archiving"
    echo -e "  ${C_BOLD}3)${C_RESET} Cancel"
    echo
    read -rp "$(echo -e "${C_CYAN}Your choice [1-3]: ${C_RESET}")" choice || true
fi

case "${choice:-3}" in
    1)
        archive_name="build_$(date +"%d.%m.%Y_%H-%M-%S").tar.gz"
        archive_path="${BACKUP_KERNEL}/${archive_name}"
        if [[ "$LANG_MODE" == "ru" ]]; then
            echo -e "\n${C_BLUE}==> Архивирую ./temp в ${archive_path}...${C_RESET}"
        else
            echo -e "\n${C_BLUE}==> Archiving ./temp to ${archive_path}...${C_RESET}"
        fi
        tar -czf "${archive_path}" -C "${ROOT_DIR}" temp
        if [[ "$LANG_MODE" == "ru" ]]; then
            echo -e "${C_GREEN}==> Архив сохранен: ${archive_path} ($(du -sh "${archive_path}" | cut -f1))${C_RESET}"
            echo -e "${C_BLUE}==> Удаляю папку ./temp...${C_RESET}"
        else
            echo -e "${C_GREEN}==> Archive saved: ${archive_path} ($(du -sh "${archive_path}" | cut -f1))${C_RESET}"
            echo -e "${C_BLUE}==> Removing ./temp directory...${C_RESET}"
        fi
        rm -rf "${TEMP_DIR}"
        if [[ "$LANG_MODE" == "ru" ]]; then
            echo -e "${C_GREEN}==> Папка ./temp успешно очищена!${C_RESET}"
        else
            echo -e "${C_GREEN}==> Directory ./temp successfully cleaned!${C_RESET}"
        fi
        ;;
    2)
        if [[ "$LANG_MODE" == "ru" ]]; then
            echo -e "\n${C_BLUE}==> Удаляю папку ./temp...${C_RESET}"
            rm -rf "${TEMP_DIR}"
            echo -e "${C_GREEN}==> Папка ./temp успешно удалена!${C_RESET}"
        else
            echo -e "\n${C_BLUE}==> Removing ./temp directory...${C_RESET}"
            rm -rf "${TEMP_DIR}"
            echo -e "${C_GREEN}==> Directory ./temp successfully removed!${C_RESET}"
        fi
        ;;
    *)
        if [[ "$LANG_MODE" == "ru" ]]; then
            echo "Отмена."
        else
            echo "Cancelled."
        fi
        ;;
esac
