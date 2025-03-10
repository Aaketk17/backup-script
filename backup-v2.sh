#!/bin/bash

# Defining help function
usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Example script with long named arguments"
    echo
    echo "Options:"
    echo "  -l, --location PATH     Path to the backup location (optional) (default: /mnt/backups)"
    echo "  -f, --folder   PATH     Folder path to backup (required)"
    echo "  -b, --bucket   NAME     S3 bucket to keep the backups (optional)"
    echo "  -n, --nofiles  NUMBER   Number of files to keep (optional) (default: 3)"
    echo "  -h, --help              Show this help message"
    echo "  -v, --verbose           Enable verbose mode"
    echo "  -e, --exclude           Exclude *.log and *.log.gz files while compressing (optional) (default: false)"
    echo
    echo "Example:"
    echo "  $0 --location /mnt/backups --folder /mnt/data --bucket mybucket --nofiles 5"
    exit 1
}

for arg in "$@"; do
    if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
        usage
    fi
done

BACKUP_LOCATION="/mnt/backups"
BACKUP_FOLDER=""
S3_BUCKET=""
NO_FILES_TO_KEEP=3
VERBOSE=false
EXCLUDE_LOG_FILES=false

TEMP=$(getopt -o l:f:b:n:ev --long location:,folder:,bucket:,nofiles:,exclude,help,verbose -- "$@") || exit 1

eval set -- "$TEMP"

while true; do
    case "$1" in
        -l|--location)
            BACKUP_LOCATION="$2"
            shift 2 ;;
        -f|--folder)
            BACKUP_FOLDER="$2"
            shift 2 ;;
        -b|--bucket)
            S3_BUCKET="$2"
            shift 2 ;;
        -n|--nofiles)
            NO_FILES_TO_KEEP="$2"
            shift 2 ;;
        -v|--verbose)
            VERBOSE=true
            shift ;;
        -e|--exclude)
            EXCLUDE_LOG_FILES=true
            shift ;;
        --)
            shift
            break ;;
        *)
            echo "Invalid option: $1" >&2
            usage ;;
    esac
done

if $VERBOSE; then
    echo 
    echo
    echo "Backup folder: $BACKUP_FOLDER"
    echo "Backup location: $BACKUP_LOCATION"
    echo "$BACKUP_FOLDER will be backed up to $BACKUP_LOCATION"
    if [ -n "$S3_BUCKET" ]; then
        echo "Files will be uploaded to S3 bucket $S3_BUCKET"
    fi
    echo "$NO_FILES_TO_KEEP files will be kept in $BACKUP_LOCATION for future usages"
    echo
    echo
fi

# Validate nofiles is a number
if ! [[ "$NO_FILES_TO_KEEP" =~ ^[0-9]+$ ]]; then
    echo "Error: --nofiles | -n must be a numeric value" >&2
    exit 2
fi

# Validate backup folder is not empty
if [ -z "$BACKUP_FOLDER" ]; then
    echo "Error: --folder | -f backup folder is required" >&2
    exit 3
fi

# Validate whether the backup folder exists
if [ -d "$BACKUP_FOLDER" ]; then
    echo "Valid backup folder"
else
    echo "Backup folder does not exist"
    exit 4
fi

# Validate whether the backup location exists
if [ -d "$BACKUP_LOCATION" ]; then
    echo "Valid backup location"
else
    echo "Backup location does not exist"
    exit 5
fi

# Change directory to parent directory of the backup folder and compress the backup folder
cd "$(dirname "$BACKUP_FOLDER")" || exit 6

# Setup current date and time in UTC
current_date_time=$(date -u "+%Y-%m-%d-%H-%M-%S")
backup_file_name="$(basename "$BACKUP_FOLDER")-$current_date_time.tar.gz"

# Added quotes around the folder name to handle spaces
if $EXCLUDE_LOG_FILES; then
    tar --exclude="*.log" --exclude="*.log.gz" -czf "$BACKUP_LOCATION/$backup_file_name" "$(basename "$BACKUP_FOLDER")"
else
    tar -czf "$BACKUP_LOCATION/$backup_file_name" "$(basename "$BACKUP_FOLDER")"
fi
if [ $? -eq 0 ]; then
    echo "Backup is successful and the backup file $backup_file_name is stored in $BACKUP_LOCATION"
else
    echo "Backup failed"
    exit 7
fi

# Upload the backup to S3 if the bucket is provided
if [ -n "$S3_BUCKET" ]; then
    if ! command -v aws &> /dev/null; then
        echo "Error: AWS CLI is not installed. Please install it to use S3 backup feature." >&2
        exit 8
    fi
    echo "Uploading $backup_file_name to S3 bucket $S3_BUCKET"
    if ! aws s3 cp "$BACKUP_LOCATION/$backup_file_name" "s3://$S3_BUCKET/$backup_file_name"; then
        echo "Error: Failed to upload to S3 bucket" >&2
        exit 9
    fi
    echo "Backup uploaded to S3 bucket $S3_BUCKET"
fi

# Sort files by modification time (oldest first)
files=($(find "$BACKUP_LOCATION" -maxdepth 1 -mindepth 1 -type f -name "*.tar.gz" -printf '%T@ %p\n' | sort -n | cut -d ' ' -f 2-))

num_files=${#files[@]}
num_files_to_delete=$((num_files - NO_FILES_TO_KEEP))
echo "Number of files to delete: $num_files_to_delete"
if [ $num_files_to_delete -le 0 ]; then
    echo "No old backups to delete."
    exit 0
fi

# Delete the oldest 'num_files_to_delete' files
for (( i=0; i < num_files_to_delete; i++ )); do
    echo "Deleting old backup file: ${files[$i]}"
    rm -f "${files[$i]}"
done

echo "Cleanup completed. Kept $NO_FILES_TO_KEEP latest backups."
echo "Backup completed successfully !!"