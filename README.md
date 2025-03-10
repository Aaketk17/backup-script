# Backup Script User Manual

This manual documents the usage, options, examples, error codes, and best practices for the backup script. The script compresses a specified folder, stores the backup in a local location, optionally uploads the backup to an AWS S3 bucket, and cleans up old backups.

---

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
- [Command-Line Options](#command-line-options)
- [Example Commands](#example-commands)
- [Error Codes](#error-codes)
- [How the Script Works](#how-the-script-works)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

---

## Overview

This bash script performs the following tasks:

- Parses command-line options for flexible configuration.
- Validates the existence of the backup folder and the backup location.
- Compresses the backup folder into a timestamped tar.gz archive.
- Optionally uploads the archive to an AWS S3 bucket if provided.
- Keeps a specified number of backups by deleting older files.

---

## Prerequisites

Before using the script, ensure that your environment meets these requirements:

- **Operating System:** Linux/Unix-like environment with Bash installed.
- **Tools:**
  - `tar`
  - `getopt` (GNU version recommended)
- **Optional (for S3 Upload):**
  - AWS CLI installed and configured with valid credentials.

---

## Usage

Run the script with the required and optional arguments:

```bash
./backup.sh [OPTIONS]
```

To display the help message:

```bash
./backup.sh --help
```

---

## Command-Line Options

| Option                 | Description                                                          | Default Value  | Required? |
| ---------------------- | -------------------------------------------------------------------- | -------------- | --------- |
| `-l, --location PATH`  | Path to the backup location.                                         | `/mnt/backups` | No        |
| `-f, --folder PATH`    | Folder path to backup.                                               | –              | **Yes**   |
| `-b, --bucket NAME`    | S3 bucket name to upload the backup.                                 | –              | No        |
| `-n, --nofiles NUMBER` | Number of backup files to keep.                                      | `3`            | No        |
| `-v, --verbose`        | Enable verbose mode to output detailed processing information.       | false          | No        |
| `-e, --exclude`        | Exclude `*.log` and `*.log.gz` files during the compression process. | false          | No        |
| `-h, --help`           | Show the help message.                                               | –              | No        |

---

## Example Commands

1. **Basic Backup**
   Backup the folder `/mnt/data` using the default backup location and number of files (3):

   ```bash
   ./backup.sh --folder /mnt/data
   ```

2. **Custom Backup Location and File Retention**
   Backup `/mnt/data` to `/backup/path` and keep 5 backup files:

   ```bash
   ./backup.sh --location /backup/path --folder /mnt/data --nofiles 5
   ```

3. **Backup with S3 Upload**
   Backup `/mnt/data` and upload the archive to an S3 bucket named `mybucket`:

   ```bash
   ./backup.sh --folder /mnt/data --bucket mybucket
   ```

4. **Verbose Mode with Log Exclusion**
   Backup a folder with spaces in its name, enable verbose output, and exclude log files:
   ```bash
   ./backup.sh --folder "/mnt/my data" --verbose --exclude
   ```

---

## Error Codes

The script exits with the following error codes on failure:

- **1:** General usage error (invalid option or failure in parsing arguments).
- **2:** The `--nofiles` parameter is not a numeric value.
- **3:** The `--folder` parameter is missing (required).
- **4:** The specified backup folder does not exist.
- **5:** The specified backup location does not exist.
- **6:** Failed to change directory to the backup folder's parent directory.
- **7:** Compression (tar command) failed.
- **8:** AWS CLI is not installed (required for S3 upload).
- **9:** S3 upload failed.

---

## How the Script Works

1. **Option Parsing:**
   The script uses `getopt` to handle both short and long options. It sets default values for optional parameters.

2. **Validation:**
   It validates that:

   - The backup folder is provided and exists.
   - The backup location exists.
   - The `--nofiles` option is numeric.

3. **Compression:**

   - Changes to the parent directory of the backup folder.
   - Compresses the folder into a tar.gz archive with a UTC timestamp appended to the filename.
   - Optionally excludes log files if the `--exclude` flag is set.

4. **S3 Upload (Optional):**
   If a bucket name is provided, the script checks for AWS CLI installation and uploads the backup file to the specified S3 bucket.

5. **Cleanup:**
   - Lists all backup files in the backup location.
   - Deletes the oldest backups, keeping only the most recent files as specified by the `--nofiles` option.

---

## Best Practices

- **Ensure Valid Paths:**
  Double-check that both the backup folder and backup location exist and have appropriate permissions before executing the script.

- **Regular Testing:**
  Periodically test the script in a safe environment to verify that compression, upload, and cleanup operations work as expected.

- **Scheduling Backups:**
  Use a cron job or another scheduler to automate backups based on your organization’s requirements.

- **AWS CLI Configuration:**
  If using S3 upload, ensure the AWS CLI is correctly installed and configured with the necessary permissions.

- **Verbose Mode:**
  Use the `--verbose` option when running the script for the first time or for troubleshooting, to get detailed output.

- **Backup Retention:**
  Adjust the `--nofiles` option to balance between disk usage and backup retention policy. Regularly monitor the backup location for sufficient storage.

---

## Troubleshooting

- **Invalid Option Errors:**
  Check that you are using supported options (`-l, -f, -b, -n, -v, -e`) and that the syntax is correct.

- **Directory Not Found:**
  Verify the paths provided for the backup folder and backup location. They must exist before running the script.

- **AWS CLI Issues:**
  If S3 uploads fail, confirm that AWS CLI is installed and configured with valid credentials and that you have network access.

- **Permission Errors:**
  Ensure you have the proper permissions to read the backup folder and write to the backup location. Running the script with elevated privileges (e.g., using `sudo`) may be necessary in some cases.

---

By following the guidelines in this manual, you can effectively use the backup script to manage your data backups while maintaining control over storage and retention policies.
