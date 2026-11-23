#!/usr/bin/env bash
# ==============================================================================
# LostLink - Unix & Shell Scripting Campus Lost & Found System
# Module: backup_cron.sh (Member 4: Scheduled Automated Cron Job)
# Setup in Linux:
#   crontab -e
#   0 0 * * * /path/to/LostLink/cron/backup_cron.sh >> /path/to/LostLink/logs/cron.log 2>&1
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(cd "$SCRIPT_DIR/../backend" && pwd)"
LOG_DIR="$(cd "$SCRIPT_DIR/../logs" && pwd)"
CRON_LOG="$LOG_DIR/cron.log"

mkdir -p "$LOG_DIR"

timestamp=$(date "+%Y-%m-%d %H:%M:%S")
echo "[$timestamp] [CRON_START] Initiating scheduled automated backup and rotation..." >> "$CRON_LOG"

# Execute backup with 7-day retention
if bash "$BACKEND_DIR/backup_restore.sh" create 7 >> "$CRON_LOG" 2>&1; then
    echo "[$timestamp] [CRON_SUCCESS] Scheduled backup completed successfully." >> "$CRON_LOG"
else
    echo "[$timestamp] [CRON_FAILURE] Scheduled backup failed!" >> "$CRON_LOG"
fi
