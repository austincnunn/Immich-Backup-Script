#!/bin/bash

# Immich Backup Script
# Configuration
CONTAINERS=("immich-server" "immich_postgres" "immich_machine_learning" "immich_redis")
BACKUP_SOURCE="/var/lib/docker/volumes"  # Adjust if your Docker volumes are elsewhere
BACKUP_DEST="/mnt/unraid/immich-backup"
LOG_FILE="/tmp/immich-backup-$(date +%Y%m%d-%H%M%S).log"
EMAIL="austin@austinnunn.net"
SMTP_SERVER="in-v3.mailjet.com"  # Replace with your SMTP relay
SMTP_PORT="587"  # Adjust if needed

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to send email
send_email() {
    local subject="Immich Backup Report - $(date '+%Y-%m-%d %H:%M:%S')"

    # Using mailx with config file
    mailx -s "$subject" "$EMAIL" < "$LOG_FILE"

    log_message "Email notification sent to $EMAIL"
}


# Main backup process
log_message "Starting Immich backup process"

# Stop Immich containers
log_message "Stopping Immich containers..."
for container in "${CONTAINERS[@]}"; do
    if docker stop "$container" >> "$LOG_FILE" 2>&1; then
        log_message "Stopped container: $container"
    else
        log_message "Warning: Failed to stop container $container or it doesn't exist"
    fi
done

# Perform incremental backup using rsync
log_message "Starting incremental backup to $BACKUP_DEST"
if rsync -avh --delete --progress "$BACKUP_SOURCE" "$BACKUP_DEST" >> "$LOG_FILE" 2>&1; then
    log_message "Backup completed successfully"
    BACKUP_STATUS="SUCCESS"
else
    log_message "Backup failed"
    BACKUP_STATUS="FAILED"
fi

# Restart Immich containers
log_message "Restarting Immich containers..."
for container in "${CONTAINERS[@]}"; do
    if docker start "$container" >> "$LOG_FILE" 2>&1; then
        log_message "Started container: $container"
    else
        log_message "Warning: Failed to start container $container"
    fi
done

# Send completion email
send_email

log_message "Immich backup process completed with status: $BACKUP_STATUS"
echo "Backup process completed. Check $LOG_FILE for details."
