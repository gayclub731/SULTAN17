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
    if [[ -d "${SULTAN_SRC}" && ! -d "${SULTAN_SRC}/.git" ]]; then
        if [[ "${CURRENT_LANG}" == "ru" ]]; then
            echo -e "${C_YELLOW}==> .git не обнаружен в sultan/. Инициализация локального репозитория...${C_RESET}"
        else
            echo -e "${C_YELLOW}==> .git not found in sultan/. Initializing local git repository...${C_RESET}"
        fi
        (
            cd "${SULTAN_SRC}"
            git init
            git config user.name "SultanBuilder"
            git config user.email "builder@localhost"
            git add -A
            git commit -m "Sultan 17.0.0-cp3a (73a5a59574cadd7b14af50442f3381c8cd7623cf)"
        )
        if [[ "${CURRENT_LANG}" == "ru" ]]; then
            echo -e "${C_GREEN}==> Git-репозиторий успешно инициализирован!${C_RESET}"
        else
            echo -e "${C_GREEN}==> Git repository successfully initialized!${C_RESET}"
        fi
    fi
}

check_platform_tools() {
    if [[ ! -x "${ADB_BIN}" || ! -x "${FASTBOOT_BIN}" ]]; then
        if [[ "${CURRENT_LANG}" == "ru" ]]; then
            echo -e "${C_YELLOW}==> Бинарники platform-tools не найдены в ${ADB_DIR}.${C_RESET}"
            echo -e "    Загрузка официального пакета Google platform-tools..."
        else
            echo -e "${C_YELLOW}==> platform-tools binaries not found in ${ADB_DIR}.${C_RESET}"
            echo -e "    Downloading official Google platform-tools package..."
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

check_host_dependencies() {
    local missing=()
    local needed=(make bc bison flex lz4 curl jq zip unzip tar python3 git)
    for tool in "${needed[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing+=("$tool")
        fi
    done

    if (( ${#missing[@]} > 0 )); then
        if [[ "${CURRENT_LANG}" == "ru" ]]; then
            echo -e "${C_YELLOW}Предупреждение: на этом компьютере отсутствуют некоторые утилиты: ${missing[*]}${C_RESET}"
            echo -e "Для Ubuntu/Debian установите их командой:"
            echo -e "${C_CYAN}  sudo apt install -y build-essential bc bison flex lz4 curl jq zip unzip tar python3 git libelf-dev libssl-dev${C_RESET}\n"
        else
            echo -e "${C_YELLOW}Warning: some build tools are missing on this PC: ${missing[*]}${C_RESET}"
            echo -e "For Ubuntu/Debian, install them via:"
            echo -e "${C_CYAN}  sudo apt install -y build-essential bc bison flex lz4 curl jq zip unzip tar python3 git libelf-dev libssl-dev${C_RESET}\n"
        fi
        return 1
    fi
    return 0
}
