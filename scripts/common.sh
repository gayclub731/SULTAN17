#!/usr/bin/env bash
# ==============================================================================
# SULTAN TOOLKIT - COMMON ENVIRONMENT & HELPERS
# ==============================================================================
set -Eeuo pipefail

SCRIPT_BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export ROOT_DIR="${SCRIPT_BASE_DIR}"
export SULTAN_SRC="${ROOT_DIR}/sultan"
export TEMP_DIR="${ROOT_DIR}/temp"
export RELEASE_DIR="${ROOT_DIR}/release"
export BACKUP_DIR="${ROOT_DIR}/backup"
export BACKUP_ANDROID="${BACKUP_DIR}/android"
export BACKUP_KERNEL="${BACKUP_DIR}/kernel"
export ADB_DIR="${ROOT_DIR}/adb"
export ADB_BIN="${ADB_DIR}/adb"
export FASTBOOT_BIN="${ADB_DIR}/fastboot"
export CONFIG_LANG_FILE="${ROOT_DIR}/.lang"

# Avoid git "dubious ownership" error if directory moved to another user or path
export GIT_CONFIG_COUNT=1
export GIT_CONFIG_KEY_0="safe.directory"
export GIT_CONFIG_VALUE_0="*"

# Colors
export C_RESET="\033[0m"
export C_BOLD="\033[1m"
export C_DIM="\033[2m"
export C_RED="\033[1;31m"
export C_GREEN="\033[1;32m"
export C_YELLOW="\033[1;33m"
export C_BLUE="\033[1;34m"
export C_MAGENTA="\033[1;35m"
export C_CYAN="\033[1;36m"
export C_WHITE="\033[1;37m"

# Get current language (default: en)
get_current_lang() {
    if [[ -f "${CONFIG_LANG_FILE}" ]]; then
        local saved_lang
        saved_lang="$(cat "${CONFIG_LANG_FILE}" | tr -d '[:space:]')"
        if [[ "$saved_lang" == "ru" || "$saved_lang" == "en" ]]; then
            echo "$saved_lang"
            return
        fi
    fi
    echo "en"
}

set_current_lang() {
    local new_lang="$1"
    echo "$new_lang" > "${CONFIG_LANG_FILE}"
}

export CURRENT_LANG="$(get_current_lang)"

ensure_base_dirs() {
    mkdir -p "${RELEASE_DIR}" "${BACKUP_ANDROID}" "${BACKUP_KERNEL}" "${ADB_DIR}"
    ensure_git_repo
}

# Auto-recreate git repository if folder transferred without .git
ensure_git_repo() {
    if [[ ! -d "${ROOT_DIR}/.git" && ! -d "${SULTAN_SRC}/.git" ]]; then
        if [[ "${CURRENT_LANG}" == "ru" ]]; then
            echo -e "${C_YELLOW}==> .git не обнаружен. Инициализация локального репозитория...${C_RESET}"
        else
            echo -e "${C_YELLOW}==> .git not found. Initializing local git repository...${C_RESET}"
        fi
        (
            cd "${ROOT_DIR}"
            git init
            git config user.name "gayclub731"
            git config user.email "gayclub731@users.noreply.github.com"
            git add -A
            git commit -m "Initial commit: Sultan 17.0.0-cp3a"
        )
        if [[ "${CURRENT_LANG}" == "ru" ]]; then
            echo -e "${C_GREEN}==> Git-репозиторий успешно инициализирован!${C_RESET}"
        else
            echo -e "${C_GREEN}==> Git repository successfully initialized!${C_RESET}"
        fi
    fi
}

check_toolchain() {
    local tc_gcc="${SULTAN_SRC}/toolchains/gcc-14.2.0-nolibc/aarch64-linux/bin/aarch64-linux-gcc"
    if [[ -x "${tc_gcc}" ]]; then
        # Toolchain is already bundled inside sultan/toolchains! No need to install GCC on the host.
        return 0
    fi

    if [[ "${CURRENT_LANG}" == "ru" ]]; then
        echo -e "${C_RED}Ошибка: Тулчейн GCC 14.2.0 не найден в ${tc_gcc}!${C_RESET}"
    else
        echo -e "${C_RED}Error: GCC 14.2.0 toolchain not found at ${tc_gcc}!${C_RESET}"
    fi
    return 1
}

check_platform_tools() {
    if [[ ! -x "${ADB_BIN}" || ! -x "${FASTBOOT_BIN}" ]]; then
        if [[ "${CURRENT_LANG}" == "ru" ]]; then
            echo -e "${C_YELLOW}==> Бинарники platform-tools не найдены в ${ADB_DIR}.${C_RESET}"
            echo -e "    Автоматическая загрузка официального пакета Google platform-tools..."
        else
            echo -e "${C_YELLOW}==> platform-tools binaries not found in ${ADB_DIR}.${C_RESET}"
            echo -e "    Auto-downloading official Google platform-tools package..."
        fi
        mkdir -p "${ADB_DIR}"
        curl -fsSL https://dl.google.com/android/repository/platform-tools-latest-linux.zip -o /tmp/platform-tools.zip
        unzip -q -o /tmp/platform-tools.zip -d /tmp/pt_extracted
        cp -r /tmp/pt_extracted/platform-tools/* "${ADB_DIR}/"
        chmod +x "${ADB_BIN}" "${FASTBOOT_BIN}"
        rm -rf /tmp/platform-tools.zip /tmp/pt_extracted
        if [[ "${CURRENT_LANG}" == "ru" ]]; then
            echo -e "${C_GREEN}==> Platform-tools успешно установлены в ${ADB_DIR}!${C_RESET}"
        else
            echo -e "${C_GREEN}==> Platform-tools successfully installed in ${ADB_DIR}!${C_RESET}"
        fi
    fi
}

auto_install_dependencies() {
    local missing_bins=()
    local needed_bins=(make bc bison flex lz4 curl jq zip unzip tar python3 git)
    for tool in "${needed_bins[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing_bins+=("$tool")
        fi
    done

    local install_cmd=""
    local pkgs_to_install=()

    if command -v apt-get >/dev/null 2>&1; then
        local apt_pkgs=()
        for b in "${missing_bins[@]}"; do
            case "$b" in
                make) apt_pkgs+=(build-essential) ;;
                *) apt_pkgs+=("$b") ;;
            esac
        done
        if ! dpkg -s libelf-dev >/dev/null 2>&1; then apt_pkgs+=(libelf-dev); fi
        if ! dpkg -s libssl-dev >/dev/null 2>&1; then apt_pkgs+=(libssl-dev); fi

        if (( ${#apt_pkgs[@]} > 0 )); then
            mapfile -t pkgs_to_install < <(printf "%s\n" "${apt_pkgs[@]}" | sort -u)
            install_cmd="sudo apt-get update && sudo apt-get install -y ${pkgs_to_install[*]}"
        fi
    elif command -v pacman >/dev/null 2>&1; then
        local arch_pkgs=()
        for b in "${missing_bins[@]}"; do
            case "$b" in
                make) arch_pkgs+=(base-devel) ;;
                *) arch_pkgs+=("$b") ;;
            esac
        done
        if (( ${#arch_pkgs[@]} > 0 )); then
            mapfile -t pkgs_to_install < <(printf "%s\n" "${arch_pkgs[@]}" | sort -u)
            install_cmd="sudo pacman -S --needed --noconfirm ${pkgs_to_install[*]}"
        fi
    elif command -v dnf >/dev/null 2>&1; then
        local dnf_pkgs=()
        for b in "${missing_bins[@]}"; do
            case "$b" in
                make) dnf_pkgs+=(gcc make) ;;
                *) dnf_pkgs+=("$b") ;;
            esac
        done
        if ! rpm -q elfutils-libelf-devel >/dev/null 2>&1; then dnf_pkgs+=(elfutils-libelf-devel); fi
        if ! rpm -q openssl-devel >/dev/null 2>&1; then dnf_pkgs+=(openssl-devel); fi
        if (( ${#dnf_pkgs[@]} > 0 )); then
            mapfile -t pkgs_to_install < <(printf "%s\n" "${dnf_pkgs[@]}" | sort -u)
            install_cmd="sudo dnf install -y ${pkgs_to_install[*]}"
        fi
    fi

    if [[ -n "$install_cmd" && (( ${#pkgs_to_install[@]} > 0 )) ]]; then
        if [[ "${CURRENT_LANG}" == "ru" ]]; then
            echo -e "${C_YELLOW}==> Обнаружены недостающие системные зависимости для сборки: ${C_BOLD}${pkgs_to_install[*]}${C_RESET}"
            read -rp "$(echo -e "${C_CYAN}Доустановить их автоматически через sudo? [Y/n]: ${C_RESET}")" ans_inst || true
        else
            echo -e "${C_YELLOW}==> Missing system build dependencies detected: ${C_BOLD}${pkgs_to_install[*]}${C_RESET}"
            read -rp "$(echo -e "${C_CYAN}Automatically install them now via sudo? [Y/n]: ${C_RESET}")" ans_inst || true
        fi
        ans_inst="${ans_inst:-Y}"
        if [[ "$ans_inst" =~ ^[YyДд]$ ]]; then
            if [[ "${CURRENT_LANG}" == "ru" ]]; then
                echo -e "${C_BLUE}Выполняю команду: ${install_cmd}${C_RESET}"
            else
                echo -e "${C_BLUE}Running command: ${install_cmd}${C_RESET}"
            fi
            eval "$install_cmd"
            if [[ "${CURRENT_LANG}" == "ru" ]]; then
                echo -e "${C_GREEN}==> Зависимости успешно установлены!${C_RESET}\n"
            else
                echo -e "${C_GREEN}==> Dependencies successfully installed!${C_RESET}\n"
            fi
        else
            if [[ "${CURRENT_LANG}" == "ru" ]]; then
                echo -e "${C_YELLOW}Установка пропущена. Убедитесь, что все пакеты установлены вручную.${C_RESET}\n"
            else
                echo -e "${C_YELLOW}Installation skipped. Please ensure packages are installed manually.${C_RESET}\n"
            fi
        fi
    fi
}
