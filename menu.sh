#!/usr/bin/env bash
# ==============================================================================
# SULTAN KERNEL BUILDER & DEVICE TOOLKIT (TUI)
# ==============================================================================
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/common.sh
source "${SCRIPT_DIR}/scripts/common.sh"

print_header() {
    clear 2>/dev/null || true
    local lang_badge="[ EN ]"
    if [[ "${CURRENT_LANG}" == "ru" ]]; then
        lang_badge="[ RU ]"
    fi

    echo -e "${C_CYAN}╔════════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_CYAN}║${C_RESET}     ${C_BOLD}${C_WHITE}SULTAN KERNEL BUILDER & DEVICE TOOLKIT (TUI)${C_RESET}       ${C_YELLOW}${lang_badge}${C_RESET}     ${C_CYAN}║${C_RESET}"
    echo -e "${C_CYAN}║${C_RESET}     ${C_DIM}Sultan 17.0.0-cp3a • Pixel gs201 / zuma / zumapro${C_RESET}              ${C_CYAN}║${C_RESET}"
    echo -e "${C_CYAN}╚════════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo
}

pause() {
    echo
    if [[ "${CURRENT_LANG}" == "ru" ]]; then
        read -rp "$(echo -e "${C_DIM}Нажмите [Enter] для возврата в меню...${C_RESET}")" _ || true
    else
        read -rp "$(echo -e "${C_DIM}Press [Enter] to return to menu...${C_RESET}")" _ || true
    fi
}

toggle_language() {
    if [[ "${CURRENT_LANG}" == "en" ]]; then
        CURRENT_LANG="ru"
    else
        CURRENT_LANG="en"
    fi
    set_current_lang "${CURRENT_LANG}"
}

main_menu() {
    ensure_base_dirs
    check_platform_tools
    check_toolchain || true
    auto_install_dependencies
    while true; do
        print_header
        if [[ "${CURRENT_LANG}" == "ru" ]]; then
            echo -e "${C_BOLD}${C_WHITE}ГЛАВНОЕ МЕНЮ:${C_RESET}"
            echo -e "  ${C_BOLD}${C_GREEN}[ 1 ]${C_RESET} ${C_BOLD}Сборка ядра${C_RESET} (gs201, zuma, zumapro | KSU / SUSFS / VPNHide + NoMount)"
            echo -e "  ${C_BOLD}${C_YELLOW}[ 2 ]${C_RESET} ${C_BOLD}Очистка папки ./temp${C_RESET} (с возможностью архивации)"
            echo -e "  ${C_BOLD}${C_CYAN}[ 3 ]${C_RESET} ${C_BOLD}Бэкап разделов телефона${C_RESET} (boot, init_boot, dtbo и др. через ADB/Fastboot)"
            echo -e "  ${C_BOLD}${C_BLUE}[ 4 ]${C_RESET} Проверить актуальность патчей upstream (Check Upstream)"
            echo -e "  ${C_BOLD}${C_MAGENTA}[ L ]${C_RESET} Сменить язык / Change Language (Текущий: ${C_BOLD}Русский${C_RESET})"
            echo -e "  ${C_BOLD}[ 0 ]${C_RESET} Выход"
            echo
            read -rp "$(echo -e "${C_CYAN}Выберите пункт [1-4, L, 0]: ${C_RESET}")" choice || true
        else
            echo -e "${C_BOLD}${C_WHITE}MAIN MENU:${C_RESET}"
            echo -e "  ${C_BOLD}${C_GREEN}[ 1 ]${C_RESET} ${C_BOLD}Build Kernel${C_RESET} (gs201, zuma, zumapro | KSU / SUSFS / VPNHide + NoMount)"
            echo -e "  ${C_BOLD}${C_YELLOW}[ 2 ]${C_RESET} ${C_BOLD}Clean ./temp Directory${C_RESET} (with optional archiving)"
            echo -e "  ${C_BOLD}${C_CYAN}[ 3 ]${C_RESET} ${C_BOLD}Backup Device Partitions${C_RESET} (boot, init_boot, dtbo, etc. via ADB/Fastboot)"
            echo -e "  ${C_BOLD}${C_BLUE}[ 4 ]${C_RESET} Check Upstream Updates (KSU, SusFS, NoMount, VPNHide)"
            echo -e "  ${C_BOLD}${C_MAGENTA}[ L ]${C_RESET} Change Language / Сменить язык (Current: ${C_BOLD}English${C_RESET})"
            echo -e "  ${C_BOLD}[ 0 ]${C_RESET} Exit"
            echo
            read -rp "$(echo -e "${C_CYAN}Select option [1-4, L, 0]: ${C_RESET}")" choice || true
        fi

        case "${choice:-0}" in
            1)
                print_header
                bash "${SCRIPT_DIR}/scripts/build_kernel.sh" --lang "${CURRENT_LANG}" || true
                pause
                ;;
            2)
                print_header
                bash "${SCRIPT_DIR}/scripts/clean_temp.sh" --lang "${CURRENT_LANG}" || true
                pause
                ;;
            3)
                print_header
                bash "${SCRIPT_DIR}/scripts/backup_device.sh" --lang "${CURRENT_LANG}" || true
                pause
                ;;
            4)
                print_header
                bash "${SCRIPT_DIR}/scripts/check_upstream.sh" --lang "${CURRENT_LANG}" || true
                pause
                ;;
            [Ll]|[Дд])
                toggle_language
                ;;
            0|[Qq])
                if [[ "${CURRENT_LANG}" == "ru" ]]; then
                    echo -e "\n${C_GREEN}До свидания!${C_RESET}"
                else
                    echo -e "\n${C_GREEN}Goodbye!${C_RESET}"
                fi
                exit 0
                ;;
            *)
                if [[ "${CURRENT_LANG}" == "ru" ]]; then
                    echo -e "\n${C_RED}Неверный пункт меню.${C_RESET}"
                else
                    echo -e "\n${C_RED}Invalid option.${C_RESET}"
                fi
                sleep 1
                ;;
        esac
    done
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main_menu
fi
