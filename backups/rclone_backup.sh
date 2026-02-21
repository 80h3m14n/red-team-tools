#!/bin/bash

# Usage:
# chmod +x ~/scripts/rclone_backup.sh
# crontab -e
# */20 * * * * flock -n /tmp/rclone_backup.lock /home/YOUR_USERNAME/scripts/rclone_backup.sh >> /home/YOUR_USERNAME/scripts/backup.log 2>&1

#!/bin/bash

PATH=/usr/bin:/bin

echo "📤 Starting Sync to Google Drive..."
echo "🕐 $(/usr/bin/date)"

FOLDERS=(
    "Bug-hunting"
    "CTF"
    "DockerImages"
    "Documents"
    "Malware"
    "Pictures"
    "Projects"
    "Scripts"
    "Vulnerable-labs"
    "wordlists"
)


for FOLDER in "${FOLDERS[@]}"; do
    SRC="$HOME/$FOLDER"
    DEST="gdrive:LinuxCloudBackup/$FOLDER"

    if [ -d "$SRC" ]; then
        echo "🔄 Syncing $FOLDER to cloud.."
        /usr/bin/rclone sync "$SRC" "$DEST" --progress
    else
        echo "⚠️ Skipped: $FOLDER not found!."
    fi
done

TIME_DONE=$(/usr/bin/date)
echo "✅ All backups complete at $TIME_DONE"

# 🔔 Desktop notification (requires libnotify-bin)
/usr/bin/notify-send "Rclone Backup" "✅ All folders synced at $TIME_DONE"
