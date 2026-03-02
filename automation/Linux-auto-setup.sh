#!/usr/bin/env bash

set -euo pipefail

########################
# Enhanced cross-distro setup script for pentest/recon/dev tools
# Usage: chmod +x Linux-auto-setup.sh && ./Linux-auto-setup.sh [--force]
# WARNING: Use ONLY in isolated VM/lab environment.
########################

# Colors
RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[1;33m' NC='\033[0m'

# Logging
LOGFILE=~/setup_tools_$(date +%Y%m%d_%H%M%S).log
exec > >(tee -a "$LOGFILE") 2>&1
echo -e "${GREEN}Setup log started at $(date)${NC}"

FORCE=false
if [[ "${1:-}" == "--force" ]]; then
    FORCE=true
    shift
fi

CATEGORIES=("recon" "scan" "exploit" "anon" "post" "dfir" "net" "misc" "labs" "dev")
declare -A TOOLS

TOOLS[recon]="dirb ffuf gobuster amass subfinder theharvester gau dnsx hakrawler netdiscover dnsrecon"
TOOLS[scan]="nmap masscan arp-scan whatweb nuclei naabu enum4linux-ng wireshark tcpdump zaproxy burpsuite"
TOOLS[exploit]="binwalk hashcat hydra metasploit sqlmap wifite cmseek bettercap"
TOOLS[anon]="torsocks ufw openvpn proxychains kalitorify firejail macchanger"
TOOLS[post]="netcat chisel ligolo-ng empire socat pspy"
TOOLS[dfir]="exiftool steghide volatility3 autopsy binwalk bintext"
TOOLS[net]="apache2 curl wget httpx dnsmasq websocat mitmproxy dnsutils etherape"
TOOLS[misc]="qrencode scrcpy jq yq termshark neofetch"
TOOLS[labs]="dvwa juice-shop"
TOOLS[dev]="code git golang nodejs python3 python3-pip mysql-server redis-server php-cli rustc cargo"

APPS=("7zip" "android-studio" "flutter" "blender" "openjdk-21-jdk")

# ──────────────────────────────────────────────────────────────────────────────
# Distro / Family detection
# ──────────────────────────────────────────────────────────────────────────────
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO=${ID_LIKE:-$ID}
        DISTRO=${DISTRO%% *}  # first word
    elif [[ -f /etc/debian_version ]]; then DISTRO=debian
    elif [[ -f /etc/redhat-release ]]; then DISTRO=redhat
    elif [[ -f /etc/arch-release ]]; then DISTRO=arch
    else
        echo -e "${RED}Cannot detect distro family. Exiting.${NC}"
        exit 1
    fi

    case $DISTRO in
        *ubuntu*|*debian*|*pop*|*mint*|*kali*|*parrot*) FAMILY=debian ;;
        *fedora*|*rhel*|*centos*|*rocky*|*almalinux*) FAMILY=redhat ;;
        *arch*|*manjaro*|*endeavouros*) FAMILY=arch ;;
        *) FAMILY=unknown ;;
    esac

    if [[ $FAMILY == "unknown" ]]; then
        echo -e "${RED}Unsupported family ($DISTRO). Exiting.${NC}"
        exit 1
    fi

    echo -e "${YELLOW}Detected family → $FAMILY (distro: $DISTRO)${NC}"

    case $FAMILY in
        debian)
            PKG_UPDATE="sudo apt update && sudo apt upgrade -y"
            PKG_INSTALL="sudo apt install --no-install-recommends -y"
            PKG_7ZIP="p7zip-full"
            PKG_OPENJDK="openjdk-21-jdk"
            PKG_GO="golang-go"
            ;;
        redhat)
            PKG_UPDATE="sudo dnf update -y"
            PKG_INSTALL="sudo dnf install -y"
            PKG_7ZIP="p7zip"
            PKG_OPENJDK="java-21-openjdk-devel"
            PKG_GO="golang"
            ;;
        arch)
            PKG_UPDATE="sudo pacman -Syu --noconfirm"
            PKG_INSTALL="sudo pacman -S --noconfirm"
            PKG_7ZIP="p7zip"
            PKG_OPENJDK="jdk21-openjdk"
            PKG_GO="go"
            ;;
    esac
}

# ──────────────────────────────────────────────────────────────────────────────
# Environment checks (Go, Rust, Python)
# ──────────────────────────────────────────────────────────────────────────────
ensure_env() {
    echo -e "${YELLOW}Checking/Installing Go (required by many tools)...${NC}"
    if ! command -v go >/dev/null 2>&1 || [[ "$(go version | awk '{print $3}')" < "go1.21" ]]; then
        echo "Installing Go..."
        $PKG_INSTALL $PKG_GO || echo -e "${RED}Go install failed – some tools will skip.${NC}"
    fi
    export PATH="$HOME/go/bin:$PATH"

    echo -e "${YELLOW}Rust check (rustc/cargo)...${NC}"
    if ! command -v rustc >/dev/null 2>&1; then
        echo "Rust not found → installing rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        . "$HOME/.cargo/env"
    fi

    echo -e "${YELLOW}Python pip check...${NC}"
    python3 -m pip --version >/dev/null 2>&1 || $PKG_INSTALL python3-pip
}

# ──────────────────────────────────────────────────────────────────────────────
# Per-family package overrides
# ──────────────────────────────────────────────────────────────────────────────
declare -A PKG_MAP
case $FAMILY in
    debian)
        PKG_MAP["code"]="code"  # vscode – may need manual .deb on some
        PKG_MAP["metasploit"]="metasploit-framework"  # often not in repos
        PKG_MAP["wireshark"]="wireshark wireshark-common"
        ;;
    redhat)
        PKG_MAP["code"]="code"
        PKG_MAP["metasploit"]="metasploit"  # usually via repo or manual
        ;;
    arch)
        PKG_MAP["code"]="visual-studio-code-bin"
        ;;
esac

# ──────────────────────────────────────────────────────────────────────────────
# Functions
# ──────────────────────────────────────────────────────────────────────────────
confirm() {
    $FORCE && return 0
    read -p "$1 [y/N] " -n 1 -r
    echo
    [[ $REPLY =~ ^[Yy]$ ]]
}

install_tools() {
    local cat=$1
    if ! confirm "Install category '$cat' ?"; then return; fi

    for tool in ${TOOLS[$cat]}; do
        echo -e "${YELLOW}→ $tool${NC}"
        local pkg=${PKG_MAP[$tool]:-$tool}

        if ! $PKG_INSTALL "$pkg" >/dev/null 2>&1; then
            echo "  Package manager failed → fallback..."
            case $tool in
                subfinder)  go install -v github.com/projectdiscovery/subfinder/cmd/subfinder@latest ;;
                nuclei)     go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest ;;
                ffuf)       go install github.com/ffuf/ffuf/v2@latest ;;
                gau)        go install github.com/lc/gau/v2/cmd/gau@latest ;;
                dnsx)       go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest ;;
                naabu)      go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest ;;
                hakrawler)  go install github.com/hakluke/hakrawler@latest ;;
                chisel)     go install github.com/jpillora/chisel@latest ;;
                ligolo-ng)
                    git clone --depth 1 https://github.com/nicocha30/ligolo-ng.git ~/Utilities/ligolo-ng
                    (cd ~/Utilities/ligolo-ng && go build -o proxy ./cmd/proxy && go build -o proxy-server ./cmd/server)
                    ;;
                empire)
                    git clone --depth 1 https://github.com/BC-SECURITY/Empire.git ~/Utilities/Empire
                    ;;
                pspy)
                    git clone --depth 1 https://github.com/DominicBreuker/pspy.git ~/Utilities/pspy
                    (cd ~/Utilities/pspy && go build)
                    ;;
                enum4linux-ng)
                    git clone --depth 1 https://github.com/cddmp/enum4linux-ng.git ~/Utilities/enum4linux-ng
                    ;;
                volatility3)
                    git clone --depth 1 https://github.com/volatilityfoundation/volatility3.git ~/Utilities/volatility3
                    ;;
                dvwa|juice-shop)
                    git clone --depth 1 https://github.com/digininja/DVWA.git ~/Utilities/dvwa || true
                    git clone --depth 1 https://github.com/juice-shop/juice-shop.git ~/Utilities/juice-shop || true
                    ;;
                *) echo "  No auto-install method known for $tool" ;;
            esac
        fi
    done
}

install_apps() {
    if ! confirm "Install general apps ?"; then return; fi

    for app in "${APPS[@]}"; do
        echo -e "${YELLOW}→ $app${NC}"
        case $app in
            7zip)           $PKG_INSTALL "${PKG_7ZIP}" ;;
            openjdk-21-jdk) $PKG_INSTALL "${PKG_OPENJDK}" ;;
            android-studio|blender)
                if command -v flatpak >/dev/null 2>&1; then
                    flatpak install -y flathub "com.${app^}.Studio" 2>/dev/null || \
                    flatpak install -y flathub org.blender.Blender
                elif command -v snap >/dev/null 2>&1; then
                    sudo snap install "$app" --classic
                else
                    echo "  No flatpak/snap → manual install needed"
                fi
                ;;
            flutter)
                git clone --depth 1 https://github.com/flutter/flutter.git ~/Apps/flutter
                export PATH="$PATH:$HOME/Apps/flutter/bin"
                flutter doctor || true
                ;;
            *) echo "  Unknown app: $app" ;;
        esac
    done
}

launcher_menu() {
    while true; do
        echo -e "\n${GREEN}Select category:${NC}"
        select opt in "${CATEGORIES[@]}" "Install Apps" "Exit"; do
            case $opt in
                "Exit") return ;;
                "Install Apps") install_apps; break ;;
                *) install_tools "$opt"; break ;;
            esac
        done
    done
}

# ──────────────────────────────────────────────────────────────────────────────
# Main
# ──────────────────────────────────────────────────────────────────────────────
echo -e "${RED}============================================================${NC}"
echo -e "${RED} WARNING: This installs powerful pentest & recon tools.${NC}"
echo -e "${RED}          Use ONLY in isolated VM/lab environment.${NC}"
echo -e "${RED}============================================================${NC}\n"

sudo -v || { echo -e "${RED}sudo access required. Exiting.${NC}"; exit 1; }

detect_distro
ensure_env

SETUP_DIRS() { mkdir -p ~/Utilities ~/Virtual-machines ~/Custom-scripts; }
SETUP_DIRS

echo -e "${YELLOW}Updating system...${NC}"
eval "$PKG_UPDATE" || echo -e "${RED}Update failed – continuing anyway${NC}"

launcher_menu

echo -e "\n${GREEN}Finished. Log: $LOGFILE${NC}"
echo "Consider adding \$HOME/go/bin and \$HOME/.cargo/bin to ~/.bashrc"
