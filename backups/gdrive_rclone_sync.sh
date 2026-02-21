#!/bin/bash

# ==========================================
# HOURLY GOOGLE DRIVE MIRROR BACKUP
# True 1:1 PC → Cloud mirror
# ==========================================

# Usage:
# chmod +x ~/scripts/gdrive_rclone_sync.sh
# crontab -e
# */20 * * * * flock -n /tmp/rclone_backup.lock /home/YOUR_USERNAME/scripts/gdrive_rclone_sync.sh >> /home/YOUR_USERNAME/scripts/backup.log 2>&1


PATH=/usr/bin:/bin

LOCKFILE="/tmp/rclone_backup.lock"
LOGFILE="$HOME/scripts/backup.log"

# Prevent overlapping runs
exec 200>$LOCKFILE
flock -n 200 || {
    echo "[$(/usr/bin/date)] Backup already running. Skipping..." >> "$LOGFILE"
    exit 1
}

echo "=========================================" >> "$LOGFILE"
echo "🔄 Starting Hourly Mirror Sync..." >> "$LOGFILE"
echo "🕐 $(/usr/bin/date)" >> "$LOGFILE"

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
        echo "🔄 Syncing $FOLDER..." >> "$LOGFILE"

        /usr/bin/rclone sync "$SRC" "$DEST" \
            --fast-list \
            --transfers=3 \
            --checkers=6 \
            --drive-chunk-size=32M \
            --tpslimit=5 \
            --bwlimit=1.6M \
            --delete-during \
            --retries=5 \
            --low-level-retries=10 \
            --timeout=10m \
            --log-level INFO \
            --log-file="$LOGFILE"

    else
        echo "⚠️ Skipped: $FOLDER not found." >> "$LOGFILE"
    fi
done

TIME_DONE=$(/usr/bin/date)
echo "✅ Mirror sync complete at $TIME_DONE" >> "$LOGFILE"
echo "=========================================" >> "$LOGFILE"



