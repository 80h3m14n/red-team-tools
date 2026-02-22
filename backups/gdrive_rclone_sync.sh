#!/bin/bash

# ==========================================
# HOURLY GOOGLE DRIVE MIRROR BACKUP
# True 1:1 PC → Cloud mirror
# Optimized for low network / 8GB RAM / SSD
# ==========================================

PATH=/usr/bin:/bin

LOCKFILE="/tmp/rclone_backup.lock"
LOGFILE="$HOME/Scripts/backup.log"


# ----------------------------
# Log Rotation (5MB limit)
# ----------------------------
MAX_LOG_SIZE=$((5 * 1024 * 1024))  # 5MB

if [ -f "$LOGFILE" ]; then
    FILESIZE=$(stat -c%s "$LOGFILE")
    if [ "$FILESIZE" -ge "$MAX_LOG_SIZE" ]; then
        mv "$LOGFILE" "$LOGFILE.$(/usr/bin/date +%Y%m%d_%H%M%S)"
        gzip "$LOGFILE."*
        find "$(dirname "$LOGFILE")" -name "backup.log.*.gz" -mtime +7 -delete
    fi
fi

# ----------------------------
# Prevent overlapping runs
# ----------------------------
exec 200>$LOCKFILE
flock -n 200 || {
    echo "[$(/usr/bin/date)] Backup already running. Skipping..." >> "$LOGFILE"
    exit 1
}

echo "=========================================" >> "$LOGFILE"
echo "🔄 Starting Hourly Mirror Sync..." >> "$LOGFILE"
echo "🕐 $(/usr/bin/date)" >> "$LOGFILE"

# ----------------------------
# Folders to backup
# ----------------------------
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


# ----------------------------
# Optional safety backup for deleted files
# ----------------------------
# SAFETY_BACKUP="--backup-dir=gdrive:LinuxCloudBackup_deleted/$(date +%Y-%m-%d)"
SAFETY_BACKUP=""

# ----------------------------
# Sync each folder
# ----------------------------
for FOLDER in "${FOLDERS[@]}"; do
    SRC="$HOME/$FOLDER"
    DEST="gdrive:LinuxCloudBackup/$FOLDER"

    echo "Checking folder: $SRC" >> "$LOGFILE"

    if [ -d "$SRC" ]; then
        echo "[$(/usr/bin/date)] 🔄 Syncing $FOLDER..." >> "$LOGFILE"

        /usr/bin/rclone sync "$SRC" "$DEST" \
           ${SAFETY_BACKUP:+--backup-dir "$SAFETY_BACKUP"}
            --fast-list \
            --transfers=8 \
            --checkers=16 \
            --drive-chunk-size=64M \
            --tpslimit=10 \
            --exclude=.venv/**
            --exclude=__pycache__/**
            --exclude='*.pyc'
            --exclude=.git/**
            --exclude=node_modules/**
            --exclude=.cache/**
            --exclude=.DS_Store
            --retries=5 \
            --low-level-retries=10 \
            --timeout=15m \
            --progress \
            --drive-acknowledge-abuse \
            --log-level INFO \
            --log-file="$LOGFILE"

    else
        echo "[$(/usr/bin/date)] ⚠️ Skipped: $FOLDER not found." >> "$LOGFILE"
    fi
done

TIME_DONE=$(/usr/bin/date)
echo "[$TIME_DONE] ✅ Mirror sync complete" >> "$LOGFILE"
echo "=========================================" >> "$LOGFILE"


# ----------------------------
# Daily Integrity Check (runs once per day)
# ----------------------------
TODAY_FILE="/tmp/rclone_last_check"
TODAY=$(/usr/bin/date +%Y-%m-%d)

if [ ! -f "$TODAY_FILE" ] || [ "$(cat $TODAY_FILE)" != "$TODAY" ]; then
    echo "[$(/usr/bin/date)] 🔎 Running daily integrity check..." >> "$LOGFILE"

    /usr/bin/rclone check "$HOME" "gdrive:LinuxCloudBackup" \
        --one-way \
        --fast-list \
        --log-level INFO \
        --log-file="$LOGFILE"

    echo "$TODAY" > "$TODAY_FILE"
    echo "[$(/usr/bin/date)] ✅ Integrity check complete." >> "$LOGFILE"
fi


# ----------------------------
# Usage Instructions (for systemd setup)
# ----------------------------

: <<'END_USAGE'

# 1️⃣ Service file
# sudo nano /etc/systemd/system/rclone-backup.service
# Paste below (replace YOUR_USERNAME):

[Unit]
Description=Rclone Google Drive Mirror Backup
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
User=YOUR_USERNAME
ExecStart=/usr/local/bin/gdrive_rclone_sync.sh
Nice=10
IOSchedulingClass=best-effort
IOSchedulingPriority=7

# 2️⃣ Timer file
# sudo nano /etc/systemd/system/rclone-backup.timer
# Paste below:

[Unit]
Description=Run Rclone Backup Every Hour

[Timer]
OnCalendar=hourly
Persistent=true

[Install]
WantedBy=timers.target

# 3️⃣ Enable timer
# sudo systemctl daemon-reload
# sudo systemctl enable --now rclone-backup.timer

# 4️⃣ Check status
# systemctl list-timers
# journalctl -u rclone-backup.service

END_USAGE
