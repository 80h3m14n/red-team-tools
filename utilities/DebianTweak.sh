#!/bin/bash

CATEGORIES=("recon" "scan" "exploit" "anon" "post" "dfir" "net" "misc" "labs")
declare -A TOOLS

TOOLS[recon]="dirb ffuf gobuster amass subfinder theharvester gau dnsx hakrawler netdiscover"
TOOLS[scan]="nmap masscan arp-scan whatweb nuclei naabu enum4linux-ng wireshark tcpdump zaproxy burpsuite"
TOOLS[exploit]="binwalk hashcat hydra metasploit sqlmap wifite cmseek bettercap"
TOOLS[anon]="torsocks ufw openvpn proxychains kalitorify firejail macof"
TOOLS[post]="netcat chisel ligolo-ng empire socat pspy"
TOOLS[dfir]="exiftool steghide volatility3 autopsy binwalk bintext"
TOOLS[net]="apache2 curl wget httpx dnsmasq websocat mitmproxy"
TOOLS[misc]="qrencode scrcpy jq yq termshark neofetch"
TOOLS[labs]="dvwa juice-shop"

APPS=("7zip" "android-studio" "flutter" "blender" "openjdk-17-jdk")

# Set up directories
SETUP_DIRS() {
  mkdir -p ~/Apps ~/Tools ~/Virtual-machines
}

# Update system
update_system() {
  sudo apt update && sudo apt upgrade -y
}

# Install apt-based tools
install_tools() {
  for tool in ${TOOLS[$1]}; do
    echo "Installing: $tool"
    sudo apt install -y $tool || {
      echo "Couldn't install $tool via APT. Checking if it's a git tool..."

      case $tool in
        subfinder)
          git clone https://github.com/projectdiscovery/subfinder.git ~/Tools/subfinder
          (cd ~/Tools/subfinder && go install)
          ;;
        hakrawler)
          git clone https://github.com/hakluke/hakrawler.git ~/Tools/hakrawler
          (cd ~/Tools/hakrawler && go install)
          ;;
        gau)
          git clone https://github.com/lc/gau.git ~/Tools/gau
          (cd ~/Tools/gau && go install)
          ;;
        ligolo-ng)
          git clone https://github.com/nicocha30/ligolo-ng.git ~/Tools/ligolo-ng
          ;;
        empire)
          git clone https://github.com/BC-SECURITY/Empire.git ~/Tools/Empire
          ;;
        pspy)
          git clone https://github.com/DominicBreuker/pspy.git ~/Tools/pspy
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
