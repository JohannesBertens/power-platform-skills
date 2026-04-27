#!/usr/bin/env bash
# ensure-pwsh.sh — Unix bootstrapper (Linux, macOS, WSL)
# Ensures pwsh (PowerShell 7) is present, then delegates to check-pac.ps1.
#
# Pinned baseline (update here when upgrading):
PWSH_VERSION="7.6.1"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---------------------------------------------------------------------------
# Helper: detect OS
# ---------------------------------------------------------------------------
detect_os() {
    if [[ "$OSTYPE" == darwin* ]]; then
        echo "macOS"
        return
    fi
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        case "${ID:-}" in
            alpine)  echo "Alpine"; return ;;
            debian)  echo "Debian"; return ;;
            ubuntu)  echo "Ubuntu"; return ;;
            rhel|centos|fedora|rocky|almalinux) echo "RHEL"; return ;;
        esac
        case "${ID_LIKE:-}" in
            *ubuntu*|*debian*) echo "Debian"; return ;;
            *rhel*|*fedora*)   echo "RHEL";   return ;;
        esac
    fi
    echo "Linux"
}

# ---------------------------------------------------------------------------
# Require sudo/root for system-level installs
# ---------------------------------------------------------------------------
check_elevation() {
    if [[ $EUID -ne 0 ]] && ! sudo -n true 2>/dev/null; then
        echo "STATUS: ACTION_REQUIRED (admin-required)"
        echo "REMEDIATION: Re-run this script with sudo, or install pwsh manually before retrying."
        echo "NEXT_COMMAND: sudo bash ${SCRIPT_DIR}/ensure-pwsh.sh $*"
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# Install PowerShell
# ---------------------------------------------------------------------------
install_pwsh_macos() {
    if command -v brew &>/dev/null; then
        echo "[INFO] Installing PowerShell via Homebrew (community-managed)…"
        brew install powershell
    else
        echo "[INFO] Homebrew not found; installing PowerShell pkg for macOS…"
        local arch
        arch="$(uname -m)"
        local arch_token="x64"
        [[ "$arch" == "arm64" ]] && arch_token="arm64"
        local pkg_url="https://github.com/PowerShell/PowerShell/releases/download/v${PWSH_VERSION}/powershell-${PWSH_VERSION}-osx-${arch_token}.pkg"
        local tmp_pkg="/tmp/pwsh-${PWSH_VERSION}.pkg"
        curl -fsSL "$pkg_url" -o "$tmp_pkg"
        sudo installer -pkg "$tmp_pkg" -target /
        rm -f "$tmp_pkg"
    fi
}

install_pwsh_debian() {
    check_elevation "$@"
    local os_ver codename
    os_ver="$(. /etc/os-release && echo "${VERSION_ID:-11}")"
    codename="$(. /etc/os-release && echo "${VERSION_CODENAME:-stable}")"
    local repo_url="https://packages.microsoft.com/repos/microsoft-debian${os_ver}-prod"
    curl -fsSL "https://packages.microsoft.com/keys/microsoft.asc" | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
    echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/microsoft-prod.gpg] ${repo_url} ${codename} main" \
        | sudo tee /etc/apt/sources.list.d/microsoft-prod.list > /dev/null
    sudo apt-get update -y
    sudo apt-get install -y powershell
}

install_pwsh_ubuntu() {
    check_elevation "$@"
    # Ubuntu may carry pwsh in its own feeds
    if sudo apt-get install -y powershell 2>/dev/null; then
        return
    fi
    # Fall back to Microsoft repo
    local arch="amd64"
    [[ "$(uname -m)" == "aarch64" ]] && arch="arm64"
    local os_ver
    os_ver="$(. /etc/os-release && echo "${VERSION_ID}")"
    local deb_url="https://packages.microsoft.com/config/ubuntu/${os_ver}/packages-microsoft-prod.deb"
    local tmp_deb="/tmp/packages-microsoft-prod.deb"
    curl -fsSL "$deb_url" -o "$tmp_deb"
    sudo dpkg -i "$tmp_deb"
    rm -f "$tmp_deb"
    sudo apt-get update -y
    sudo apt-get install -y powershell
}

install_pwsh_rhel() {
    check_elevation "$@"
    local os_ver
    os_ver="$(. /etc/os-release && echo "${VERSION_ID}" | cut -d. -f1)"
    sudo rpm --import "https://packages.microsoft.com/keys/microsoft.asc"
    curl -fsSL "https://packages.microsoft.com/config/rhel/${os_ver}/prod.repo" \
        | sudo tee /etc/yum.repos.d/microsoft-prod.repo > /dev/null
    sudo dnf install -y powershell
}

install_pwsh_alpine() {
    check_elevation "$@"
    local arch
    arch="$(uname -m)"
    local arch_token="x64"
    [[ "$arch" == "aarch64" ]] && arch_token="arm64"
    local archive="powershell-${PWSH_VERSION}-linux-musl-${arch_token}.tar.gz"
    local dl_url="https://github.com/PowerShell/PowerShell/releases/download/v${PWSH_VERSION}/${archive}"
    local tmp_tar="/tmp/${archive}"
    apk add --no-cache ca-certificates less ncurses-terminfo-base krb5-libs libgcc libintl libssl3 libstdc++ tzdata userspace-rcu zlib icu-libs curl
    curl -fsSL "$dl_url" -o "$tmp_tar"
    sudo mkdir -p /opt/microsoft/powershell/7
    sudo tar zxf "$tmp_tar" -C /opt/microsoft/powershell/7
    sudo chmod +x /opt/microsoft/powershell/7/pwsh
    sudo ln -sf /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh
    rm -f "$tmp_tar"
}

install_pwsh_linux_generic() {
    check_elevation "$@"
    local arch
    arch="$(uname -m)"
    local arch_token="x64"
    [[ "$arch" == "aarch64" ]] && arch_token="arm64"
    local archive="powershell-${PWSH_VERSION}-linux-${arch_token}.tar.gz"
    local dl_url="https://github.com/PowerShell/PowerShell/releases/download/v${PWSH_VERSION}/${archive}"
    local tmp_tar="/tmp/${archive}"
    curl -fsSL "$dl_url" -o "$tmp_tar"
    sudo mkdir -p /opt/microsoft/powershell/7
    sudo tar zxf "$tmp_tar" -C /opt/microsoft/powershell/7
    sudo chmod +x /opt/microsoft/powershell/7/pwsh
    sudo ln -sf /opt/microsoft/powershell/7/pwsh /usr/bin/pwsh
    rm -f "$tmp_tar"
}

# ---------------------------------------------------------------------------
# Ensure pwsh is available
# ---------------------------------------------------------------------------
ensure_pwsh() {
    if command -v pwsh &>/dev/null; then
        echo "[INFO] pwsh already present: $(pwsh --version 2>/dev/null || echo 'version unknown')"
        return
    fi

    echo "[INFO] pwsh not found — installing PowerShell ${PWSH_VERSION}…"
    local os
    os="$(detect_os)"

    case "$os" in
        macOS)  install_pwsh_macos  "$@" ;;
        Debian) install_pwsh_debian "$@" ;;
        Ubuntu) install_pwsh_ubuntu "$@" ;;
        RHEL)   install_pwsh_rhel   "$@" ;;
        Alpine) install_pwsh_alpine "$@" ;;
        Linux)  install_pwsh_linux_generic "$@" ;;
        *)
            echo "STATUS: ACTION_REQUIRED (pwsh-missing)"
            echo "REMEDIATION: Install PowerShell 7 for your platform and re-run this script."
            echo "NEXT_COMMAND: https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell"
            exit 1
            ;;
    esac

    if ! command -v pwsh &>/dev/null; then
        echo "STATUS: ACTION_REQUIRED (pwsh-missing)"
        echo "REMEDIATION: PowerShell install did not complete successfully. Install manually and re-run."
        echo "NEXT_COMMAND: https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell"
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
ensure_pwsh "$@"
exec pwsh -File "${SCRIPT_DIR}/check-pac.ps1" -Bootstrap "$@"
