#!/usr/bin/env bash
# shellcheck shell=bash

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=config.sh
source "${SCRIPT_DIR}/config.sh"

RELEASE_DIR="${RELEASE_DIR:-${REPO_ROOT}/../release}"
mkdir -p "${RELEASE_DIR}"

TARGET="${1:-}"
VARIANT="${2:-}"

shopt -s nullglob
FILES=("${DIST_DIR}"/*.zip)

if (( ${#FILES[@]} == 0 )); then
    die "No ZIP files found in ${DIST_DIR}"
fi

msg "Copying build artifacts to release directory: ${RELEASE_DIR}"

for f in "${FILES[@]}"; do
    cp -v "$f" "${RELEASE_DIR}/"
done

# Try loading from cached .upstream_shas if present
CACHE_FILE=""
if [[ -f "${REPO_ROOT}/.upstream_shas" ]]; then
    CACHE_FILE="${REPO_ROOT}/.upstream_shas"
elif [[ -f "${REPO_ROOT}/../.upstream_shas" ]]; then
    CACHE_FILE="${REPO_ROOT}/../.upstream_shas"
fi

if [[ -n "${CACHE_FILE}" ]]; then
    # shellcheck source=/dev/null
    source "${CACHE_FILE}" || true
fi

# Check local git clones in temp/repo if available
if [[ -z "${SUSFS_SHA:-}" || "${SUSFS_SHA:-}" == "unknown" ]]; then
    if [[ -d "${REPO_ROOT}/susfs4ksu/.git" ]]; then
        SUSFS_SHA="$(git -C "${REPO_ROOT}/susfs4ksu" rev-parse HEAD 2>/dev/null || echo 'unknown')"
    fi
fi

if [[ -z "${VPNHIDE_SHA:-}" || "${VPNHIDE_SHA:-}" == "unknown" ]]; then
    if [[ -d "${REPO_ROOT}/vpnhide/.git" ]]; then
        VPNHIDE_SHA="$(git -C "${REPO_ROOT}/vpnhide" rev-parse HEAD 2>/dev/null || echo 'unknown')"
    fi
fi

if [[ -z "${NEXT_SHA:-}" || "${NEXT_SHA:-}" == "unknown" ]]; then
    if [[ -d "${REPO_ROOT}/KernelSU-Next/.git" ]]; then
        NEXT_SHA="$(git -C "${REPO_ROOT}/KernelSU-Next" rev-parse HEAD 2>/dev/null || echo 'unknown')"
    fi
fi

if [[ -z "${KSU_SHA:-}" || "${KSU_SHA:-}" == "unknown" ]]; then
    if [[ -d "${REPO_ROOT}/KernelSU/.git" ]]; then
        KSU_SHA="$(git -C "${REPO_ROOT}/KernelSU" rev-parse HEAD 2>/dev/null || echo 'unknown')"
    fi
fi

# If any upstream SHAs are still unknown, query API via python helper
python_resolver="
import urllib.request, json

def get_gh(repo, branch, path=''):
    try:
        url = f'https://api.github.com/repos/{repo}/commits?sha={branch}&per_page=1'
        if path: url += f'&path={path}'
        req = urllib.request.Request(url, headers={'User-Agent': 'curl'})
        with urllib.request.urlopen(req, timeout=4) as r:
            return json.loads(r.read().decode())[0]['sha']
    except Exception:
        return 'unknown'

def get_gl(project, branch):
    try:
        proj_enc = project.replace('/', '%2F')
        url = f'https://gitlab.com/api/v4/projects/{proj_enc}/repository/branches/{branch}'
        req = urllib.request.Request(url, headers={'User-Agent': 'curl'})
        with urllib.request.urlopen(req, timeout=4) as r:
            return json.loads(r.read().decode())['commit']['id']
    except Exception:
        return 'unknown'

ksu = '${KSU_SHA:-unknown}'
next_s = '${NEXT_SHA:-unknown}'
sus = '${SUSFS_SHA:-unknown}'
nom = '${NOMOUNT_SHA:-unknown}'
vpn = '${VPNHIDE_SHA:-unknown}'

if ksu == 'unknown': ksu = get_gh('tiann/KernelSU', 'main', 'kernel')
if next_s == 'unknown': next_s = get_gh('KernelSU-Next/KernelSU-Next', 'dev', 'kernel')
if sus == 'unknown': sus = get_gl('simonpunk/susfs4ksu', 'gki-android14-6.1')
if nom == 'unknown': nom = get_gh('maxsteeel/nomount', 'dev', 'kernel')
if vpn == 'unknown': vpn = get_gh('okhsunrog/vpnhide', 'main', 'builtin')

print(f'KSU_SHA=\"{ksu}\"\nNEXT_SHA=\"{next_s}\"\nSUSFS_SHA=\"{sus}\"\nNOMOUNT_SHA=\"{nom}\"\nVPNHIDE_SHA=\"{vpn}\"')
"

if [[ "${KSU_SHA:-unknown}" == "unknown" || "${NEXT_SHA:-unknown}" == "unknown" || "${SUSFS_SHA:-unknown}" == "unknown" || "${NOMOUNT_SHA:-unknown}" == "unknown" || "${VPNHIDE_SHA:-unknown}" == "unknown" ]]; then
    eval "$(python3 -c "$python_resolver" 2>/dev/null || true)"
fi

# Fallback values if offline
SOURCE_SHA="${SOURCE_SHA:-$(git rev-parse HEAD 2>/dev/null || echo 'unknown')}"
KSU_SHA="${KSU_SHA:-unknown}"
NEXT_SHA="${NEXT_SHA:-unknown}"
SUSFS_SHA="${SUSFS_SHA:-unknown}"
NOMOUNT_SHA="${NOMOUNT_SHA:-unknown}"
VPNHIDE_SHA="${VPNHIDE_SHA:-unknown}"

TIMESTAMP="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

cat > "${RELEASE_DIR}/nightly.json" <<EOF
{
  "build_date": "${TIMESTAMP}",
  "source": "${SOURCE_SHA}",
  "kernelsu": "${KSU_SHA}",
  "kernelsu_next": "${NEXT_SHA}",
  "susfs": "${SUSFS_SHA}",
  "nomount": "${NOMOUNT_SHA}",
  "vpnhide": "${VPNHIDE_SHA}"
}
EOF

# Also keep a copy in dist
cp "${RELEASE_DIR}/nightly.json" "${DIST_DIR}/nightly.json"

msg "Release successfully updated in ${RELEASE_DIR}:"
ls -lh "${RELEASE_DIR}"
echo
cat "${RELEASE_DIR}/nightly.json"
