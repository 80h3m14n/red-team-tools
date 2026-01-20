#!/bin/bash

CATEGORIES=("recon" "scan" "exploit" "anon" "post" "dfir" "net" "misc" "labs")
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

APPS=("7zip" "android-studio" "flutter" "blender" "openjdk-21-jdk")

# Set up directories
SETUP_DIRS() {
  mkdir -p ~/Utilities ~/Virtual-machines ~/Custom-scripts
}

# Update system
update_system() {
  sudo apt update && sudo apt upgrade -y
}

# Install apt-based & Git tools
install_tools() {
  for tool in ${TOOLS[$1]}; do
    echo "Installing: $tool"
    sudo apt install -y $tool || {
      echo "Failed to install $tool via APT. Checking if it's a git tool..."

      case $tool in
        subfinder)
          go install -v github.com/projectdiscovery/subfinder/cmd/subfinder@latest
          ;;
        hakrawler)
          go install github.com/hakluke/hakrawler@latest
          ;;
        gau)
          go install github.com/lc/gau/v2/cmd/gau@latest
          ;;
        ligolo-ng)
          git clone https://github.com/nicocha30/ligolo-ng.git ~/Utilities/ligolo-ng
          ;;
        empire)
          git clone https://github.com/BC-SECURITY/Empire.git ~/Utilities/Empire
          ;;
        pspy)
          git clone https://github.com/DominicBreuker/pspy.git ~/Utilities/pspy
          ;;
        enum4linux)
          git clone https://github.com/CiscoCXSecurity/enum4linux
          ;;
        *)
          echo "Manual setup might be required for: $tool"
          ;;
      esac
    }
  done
}

# Install GUI/IDE apps
install_apps() {
  echo "Installing general apps..."
  for app in "${APPS[@]}"; do
    case $app in
      7zip)
        sudo apt install -y p7zip-full
        ;;
      android-studio)
        echo "Installing Android Studio..."
        sudo snap install android-studio --classic
        ;;
      flutter)
        echo "Installing Flutter..."
        git clone https://github.com/flutter/flutter.git ~/Apps/flutter
        export PATH="$PATH:$HOME/Apps/flutter/bin"
        flutter doctor
        ;;
      blender)
        sudo snap install blender --classic
        ;;
      openjdk-17-jdk)
        sudo apt install -y openjdk-17-jdk
        ;;
      *)
        echo "Unknown app: $app"
        ;;
    esac
  done
}

# Main menu
launcher_menu() {
  echo "Select a category to install tools from:"
  select opt in "${CATEGORIES[@]}" "Install Apps" "Exit"; do
    case $opt in
      Exit)
        break;;
      Install\ Apps)
        install_apps
        break;;
      *)
        echo "Installing tools for: $opt"
        install_tools "$opt"
        break;;
    esac
  done
}

SETUP_DIRS
update_system
launcher_menu
