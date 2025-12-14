#!/bin/bash

# Immich Backup Script
# Configuration
CONTAINERS=("immich_server" "immich_postgres" "immich_machine_learning" "immich_redis") # Choose which containers to stop and backup
BACKUP_SOURCE_1="/var/lib/docker/volumes"  # Adjust if your Docker volumes are elsewhere
BACKUP_SOURCE_2="/immich-app"  # Adjust if your data source is elsewhere
BACKUP_DEST="/unraid/immich_backup" # Adjust your backup destination
LOG_FILE="/tmp/immich-backup-$(date +%Y%m%d-%H%M%S).log"
EMAIL="(email)" # Enter recipient e-mail
FROMEMAIL="(email)" #Enter sender e-mail


# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to send email
send_email() {
    local subject="Immich Backup Report - $(date '+%Y-%m-%d %H:%M:%S')"

    # Using mailx with config file
    mailx -r "$FROMEMAIL" -s "$subject" "$EMAIL" < "$LOG_FILE"

    log_message "Email notification sent to $EMAIL"
}


# Main backup process
log_message "Starting Immich backup process"

# Stop Immich containers
log_message "Stopping Immich containers..."
for container in "${CONTAINERS[@]}"; do
    if sudo docker stop "$container" >> "$LOG_FILE" 2>&1; then
        log_message "Stopped container: $container"
    else
        log_message "Warning: Failed to stop container $container or it doesn't exist"
    fi
done

# Perform incremental backup of docker volumes using rsync
log_message "Starting incremental backup to $BACKUP_DEST"
if sudo rsync -avh --delete --no-devices --no-specials --progress "$BACKUP_SOURCE_1" "$BACKUP_DEST" >> "$LOG_FILE" 2>&1; then
    log_message "Backup completed successfully"
    BACKUP_STATUS="SUCCESS"
else
    log_message "Backup failed"
    BACKUP_STATUS="FAILED"
fi

# Perform incremental backup of docker data & database using rsync
log_message "Starting incremental backup to $BACKUP_DEST"
if sudo rsync -avh --delete --no-devices --no-specials --progress "$BACKUP_SOURCE_2" "$BACKUP_DEST" >> "$LOG_FILE" 2>&1; then
    log_message "Backup completed successfully"
    BACKUP_STATUS="SUCCESS"
else
    log_message "Backup failed"
    BACKUP_STATUS="FAILED"
fi

# Restart Immich containers
log_message "Restarting Immich containers..."
for container in "${CONTAINERS[@]}"; do
    if sudo docker start "$container" >> "$LOG_FILE" 2>&1; then
        log_message "Started container: $container"
    else
        log_message "Warning: Failed to start container $container"
    fi
done

# Send completion email
send_email

log_message "Immich backup process completed with status: $BACKUP_STATUS"
echo "Backup process completed. Check $LOG_FILE for details."
