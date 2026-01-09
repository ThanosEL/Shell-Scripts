#!/bin/bash
set -euo pipefail

DB_USER="username"
DB_PASS="pass"
DB_NAME="MY_DB"
BACKUP_DIR="/home/<user>/backups/mysql"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_$DATE.sql.gz"
LOG_FILE="/var/logs/mysql_backup_cron.log"

# Remote host
REMOTE_USER="<remoteuser>"
REMOTE_HOST="192.168.1.102"
REMOTE_DIR="/home/UbuntuUser2/mysql_backups"
SSH_KEY="/home/UbuntuUser3/.ssh/backup_id"

mkdir -p "$BACKUP_DIR"
echo "$(date) - Backup started" >> "$LOG_FILE"

# Dump MySQL database
mysqldump -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" | gzip > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    echo "$(date) - Backup SUCCESS: $BACKUP_FILE" >> "$LOG_FILE"
else
    echo "$(date) - Backup FAILED" >> "$LOG_FILE"
    exit 1
fi

# Keep only last 5 backups
ls -1t "$BACKUP_DIR"/*.gz 2>/dev/null | tail -n +6 | xargs -r rm --

# Ensure remote folder exists & host key added
ssh-keyscan -H "$REMOTE_HOST" >> /home/UbuntuUser3/.ssh/known_hosts 2>/dev/null
ssh -i "$SSH_KEY" "$REMOTE_USER@$REMOTE_HOST" "mkdir -p $REMOTE_DIR"

# Copy backup to remote
scp -i "$SSH_KEY" "$BACKUP_FILE" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/"

echo "$(date) - Backup finished" >> "$LOG_FILE"

