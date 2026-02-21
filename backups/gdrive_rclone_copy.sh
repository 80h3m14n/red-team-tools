#!/bin/bash

# ==========================================
# RCLONE BACKUP WITH AUTOMATIC COMPRESSION
# Optimized for 15 Mbps / 8GB RAM / SSD
# ==========================================


# Usage:
# chmod +x ~/scripts/gdrive_rclone_copy.sh
# crontab -e
# */20 * * * * flock -n /tmp/rclone_backup.lock /home/YOUR_USERNAME/scripts/gdrive_rclone_copy.sh >> /home/YOUR_USERNAME/scripts/backup.log 2>&1

PATH=/usr/bin:/bin

LOCKFILE="/tmp/rclone_backup.lock"
LOGFILE="$HOME/scripts/backup.log"
TMPDIR="$HOME/.backup_tmp"

mkdir -p "$TMPDIR"

# Prevent overlapping runs
exec 200>$LOCKFILE
flock -n 200 || {
    echo "[$(/usr/bin/date)] Backup already running. Skipping..." >> "$LOGFILE"
    exit 1
}

echo "=========================================" >> "$LOGFILE"
echo "📦 Starting Hourly Compressed Backup..." >> "$LOGFILE"
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
    TIMESTAMP=$(/usr/bin/date +"%Y-%m-%d_%H-%M")
    ARCHIVE="$TMPDIR/${FOLDER}_$TIMESTAMP.tar.gz"
    DEST="gdrive:LinuxCloudBackup/${FOLDER}.tar.gz"

    if [ -d "$SRC" ]; then
        echo "🗜 Compressing $FOLDER..." >> "$LOGFILE"

        # Multi-core compression (uses all CPU cores)
        /usr/bin/tar -I pigz -cf "$ARCHIVE" -C "$HOME" "$FOLDER"

        echo "☁ Uploading $FOLDER.tar.gz..." >> "$LOGFILE"

        /usr/bin/rclone copy "$ARCHIVE" "$DEST" \
            --transfers=1 \
            --drive-chunk-size=32M \
            --tpslimit=5 \
            --bwlimit=1.6M \
            --retries=5 \
            --low-level-retries=10 \
            --timeout=10m \
            --log-level INFO \
            --log-file="$LOGFILE"

        # Remove temp archive
        rm -f "$ARCHIVE"

    else
        echo "⚠️ Skipped: $FOLDER not found." >> "$LOGFILE"
    fi
done

TIME_DONE=$(/usr/bin/date)
echo "✅ Backup complete at $TIME_DONE" >> "$LOGFILE"
echo "=========================================" >> "$LOGFILE"
