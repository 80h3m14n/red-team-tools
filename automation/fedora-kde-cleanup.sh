#!/usr/bin/env bash

set -e

echo "Fedora KDE Cleanup Script"
echo "This will remove unnecessary default KDE apps."
echo "Removes: KDE PIM (mail/calendar stack),media apps, games, optional utilities"
echo "Optionally Disable Baloo file indexing"
echo "Core Plasma components will NOT be removed."
echo ""

read -p "Continue? (y/N): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "Removing KDE PIM (Mail/Calendar)..."
sudo dnf remove -y \
    kmail korganizer kontact akregator \
    kaddressbook pim-data-exporter \
    kdepim-runtime

echo ""
echo "Removing KDE Media Apps..."
sudo dnf remove -y \
    dragon juk elisa-player kamoso

echo ""
echo "Removing KDE Games..."
sudo dnf remove -y \
    kpat kmahjongg kmines ksudoku knavalbattle

echo ""
echo "Removing Optional Utilities..."
sudo dnf remove -y \
    kolourpaint kcharselect kruler

echo ""
echo "Autoremoving unused dependencies..."
sudo dnf autoremove -y

echo ""
echo "Disabling Baloo file indexing..."
balooctl disable || true

echo ""
echo "Consider installing VLC & Onlyoffice(if LibreOffice not suite you)"
echo "Cleanup complete!"
echo "Reboot recommended."
