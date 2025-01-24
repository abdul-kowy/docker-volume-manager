#!/bin/bash

# Default directories for temporary files
BACKUP_DIR="/tmp/backups"
RESTORE_DIR="/tmp/restore"

# Function to print usage instructions
print_usage() {
    echo "Usage: $0 [backup|restore] GCS_BUCKET"
    echo "  backup      Perform backup of all Docker volumes to the specified GCS bucket."
    echo "  restore     Restore all Docker volumes from the specified GCS bucket."
    echo "  GCS_BUCKET  The URL of the GCS bucket to use (e.g., gs://my-bucket-name)."
    exit 1
}

# Function to pause a container
pause_container() {
    local container_id=$1
    echo "Pausing container: $container_id"
    docker pause "$container_id"
}

# Function to resume a container
resume_container() {
    local container_id=$1
    echo "Resuming container: $container_id"
    docker unpause "$container_id"
}

# Function to stop a container
stop_container() {
    local container_id=$1
    echo "Stopping container: $container_id"
    docker stop "$container_id"
}

# Function to start a container
start_container() {
    local container_id=$1
    echo "Starting container: $container_id"
    docker start "$container_id"
}

# Backup function
backup_volumes() {
    local bucket_url=$1
    mkdir -p "$BACKUP_DIR"

    # Check if the GCS bucket exists
    if ! gsutil ls "$bucket_url" &> /dev/null; then
        echo "Bucket $bucket_url does not exist. Please create it manually before running this script."
        exit 1
    fi

    # Loop through all volumes and back them up
    docker volume ls -q | while read -r volume; do
        container_id=$(docker ps --filter "volume=$volume" -q)
        
        # Pause the container if it's running
        if [[ -n $container_id ]]; then
            pause_container "$container_id"
        fi

        echo "Backing up volume: $volume"
        docker run --rm -v "$volume:/volume" -v "$BACKUP_DIR:/backup" alpine tar czf "/backup/$volume.tar.gz" -C /volume .

        # Resume the container if it was paused
        if [[ -n $container_id ]]; then
            resume_container "$container_id"
        fi

        # Upload the backup to GCS
        gsutil cp "$BACKUP_DIR/$volume.tar.gz" "$bucket_url/"
    done

    echo "Backup completed!"
}

# Restore function
restore_volumes() {
    local bucket_url=$1
    mkdir -p "$RESTORE_DIR"

    # Loop through all backups in the GCS bucket and restore them
    gsutil ls "$bucket_url" | while read -r backup; do
        # Extract volume name from backup file
        volume_name=$(basename "$backup" .tar.gz)
        
        # Find the container using this volume
        container_id=$(docker ps --filter "volume=$volume_name" -q)

        # Stop the container if it's running
        if [[ -n $container_id ]]; then
            stop_container "$container_id"
        fi

        echo "Restoring volume: $volume_name"
        
        # Create the volume if it doesn't exist
        if ! docker volume inspect "$volume_name" &> /dev/null; then
            docker volume create "$volume_name"
        fi

        # Download backup from GCS
        if ! gsutil cp "$backup" "$RESTORE_DIR/$volume_name.tar.gz"; then
            echo "Failed to copy $backup to $RESTORE_DIR"
            continue
        fi

        # Extract backup to volume
        docker run --rm -v "$volume_name:/volume" -v "$RESTORE_DIR:/restore" alpine tar xzf "/restore/$volume_name.tar.gz" -C /volume

        # Restart the container if it was stopped
        if [[ -n $container_id ]]; then
            start_container "$container_id"
        fi
    done

    echo "Restore completed!"
}

# Main script logic
# Check for correct number of arguments
if [[ $# -ne 2 ]]; then
    print_usage
fi

command=$1
bucket_url=$2

# Execute the appropriate command
case $command in
    backup)
        backup_volumes "$bucket_url"
        ;;
    restore)
        restore_volumes "$bucket_url"
        ;;
    *)
        print_usage
        ;;
esac
