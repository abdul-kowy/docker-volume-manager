# Docker Volume Manager: Backup and Restore Docker Volumes

This project provides a tool to dynamically back up and restore Docker volumes to Google Cloud Storage (GCS) via a container in a Docker Compose stack. It is designed to run in an automated, simple, and secure manner while being highly configurable.

## Features

- **Backup**: Archives Docker volumes as compressed TAR files and transfers them to a GCS bucket.
- **Restore**: Downloads and extracts volume archives from a GCS bucket.
- **Automatic Detection**: Dynamically lists all available Docker volumes without manual mounting.
- **Transparent Operation**: Pauses or stops containers tied to volumes before backup/restore and resumes/restores them once done.
- **Flexible Authentication**: Compatible with GCP key files or Compute Engine service accounts with sufficient roles.
- **Configuration via Docker Compose**: Easy to integrate into existing workflows.

## Prerequisites

1. **Docker Environment**:

- Docker installed on the host machine.
- Access to the Docker API via the Docker socket (`/var/run/docker.sock`).

2. **Google Cloud Platform**:

- A project with a configured GCS bucket.
- The following permissions should be granted to the service account:
  - `roles/storage.admin` to create and manage buckets.
  - `roles/storage.objectAdmin` to manage objects.

3. **GCP Authentication**:

- Either a JSON key file for a service account configured via `gcloud auth activate-service-account`.
- Or a Compute Engine machine with an IAM identity configured.

4. **Required Packages**:

- Commands: `gsutil`, `tar`, and `docker-cli` (included in the image).

## Project Structure

### 1. Files

- **`volume_manager.sh`**: Main script managing backup and restore operations.
- **`Dockerfile`**: Docker build file to create the volume manager image.
- **`docker-compose.yml`**: Docker Compose configuration to deploy the container.

## Installation and Configuration

### 1. Clone the Project

```bash
git clone https://github.com/your-repo/volume-manager.git
cd volume-manager
```

### 2. Build the Docker Image

```bash
docker-compose build
```

### 3. Environment Variables Configuration

- Add the following variables to your `docker-compose.yml` file:
  - `GCS_BUCKET`: Name of the GCS bucket, e.g. `gs://my-bucket`.
  - `OPERATION`: `backup` or `restore` depending on the desired operation.

Example:

```yaml
version: '3.8'

services:
  volume-manager:
   image: volume-manager:latest
   environment:
    - GCS_BUCKET=gs://my-backup-bucket
    - /path/to/your/service-account-key.json:/service-account-key.json  # Optional for GCP JSON key

   volumes:
    # Mount Docker socket for accessing volumes dynamically
    - /var/run/docker.sock:/var/run/docker.sock
    # Temporary directories for backup/restore
    - /tmp/backups:/tmp/backups
    - /tmp/restore:/tmp/restore
   entrypoint: ["sh", "-c"]
   command: /usr/local/bin/volume_manager.sh backup "$GCS_BUCKET" # or /usr/local/bin/volume_manager.sh restore "$GCS_BUCKET"
```

### 4. Deploy the Container

- **Backup**:

  ```bash
  docker-compose up --force-recreate
  ```

- **Restore**:
  Change `/usr/local/bin/volume_manager.sh backup "$GCS_BUCKET"` to `/usr/local/bin/volume_manager.sh restore "$GCS_BUCKET"` in `docker-compose.yml`, then run:
  ```bash
  docker-compose up --force-recreate
  ```

## How the Script Works

The script operates in two main steps:

### 1. Backing Up Volumes

- Lists all Docker volumes via:
  ```bash
  docker volume ls -q
  ```
- For each volume:
  - Pause the associated container (if any):
  ```bash
  docker pause [ID_CONTAINERS]
  ```
  - Create a compressed archive:
  ```bash
  docker run --rm -v $volume:/volume -v $BACKUP_DIR:/backup alpine tar czf /backup/$volume.tar.gz -C /volume .
  ```
  - Unpause the container:
  ```bash
  docker unpause [ID_CONTAINERS]
  ```
  - Upload the archive to the GCS bucket:
  ```bash
  gsutil cp $BACKUP_DIR/$volume.tar.gz $GCS_BUCKET/
  ```

### 2. Restoring Volumes

- Lists the files in the GCS bucket:
  ```bash
  gsutil ls $GCS_BUCKET
  ```
- For each archive:
  - Download the archive locally:
  ```bash
  gsutil cp $GCS_BUCKET/$archive $RESTORE_DIR
  ```
  - Extract the files into the volume:
  ```bash
  docker run --rm -v $volume:/volume -v $RESTORE_DIR:/restore alpine tar xzf /restore/$archive -C /volume
  ```
  - Restart associated containers if needed.

## Key Points and Security

1. **Access to the Docker Socket**:

- The Docker socket is mounted in the container so it can perform operations on volumes and containers.
- Risk: This grants the container full permissions over the Docker instance. Ensure the script is secure.

2. **GCP Authentication**:

- If using a JSON key file, mount it as a volume and set the `GOOGLE_APPLICATION_CREDENTIALS` variable in `docker-compose.yml`.

3. **Data Retention**:

- The backup files are temporarily stored in `/tmp/backups` and `/tmp/restore`.

## Complete Usage Example

### Back Up All Docker Volumes

```bash
./volume_manager.sh backup gs://my-bucket
```

### Restore Volumes from the GCS Bucket

```bash
./volume_manager.sh restore gs://my-bucket
```

## Future Improvements

1. Add an option to exclude certain volumes.
2. Support multiple cloud platforms like AWS S3 or Azure Blob Storage.
3. Integrate automated tests to validate backup and restore operations.

## Conclusion

This project provides a flexible, extensible solution for managing Docker volumes. Its straightforward integration via Docker Compose makes it ideal for existing Docker production environments. With GCP authentication and automated operation, it ensures secure replication of critical data.
