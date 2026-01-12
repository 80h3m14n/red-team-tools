#!/bin/bash

LOGFILE="$HOME/logs/rclone-backup.log"
REMOTE="gdrive:Debian-Backup"

echo "==============================" >> "$LOGFILE"
echo "📤 Backup started at $(date)" >> "$LOGFILE"

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
    DEST="$REMOTE/$FOLDER"

    if [ -d "$SRC" ]; then
        echo "🔄 Syncing $FOLDER..." >> "$LOGFILE"
        rclone sync "$SRC" "$DEST" \
            --delete-during \
            --transfers=8 \
            --checkers=8 \
            --log-file="$LOGFILE" \
            --log-level INFO
    else
        echo "⚠️ Skipped: $FOLDER not found" >> "$LOGFILE"
    fi
done

echo "✅ Backup finished at $(date)" >> "$LOGFILE"
