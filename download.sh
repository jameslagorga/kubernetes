#!/bin/bash
set -ex

JOB_DIR="/mnt/nfs/jobs/download-buildai-dataset"
DATA_DIR="${JOB_DIR}/data"
LOG_FILE="${JOB_DIR}/${POD_NAME}.log"

main() {
  echo "Updating package list and installing dependencies..."
  apt-get update && apt-get install -y curl python3 aria2
  echo "Destination: $DATA_DIR"
  mkdir -p "$DATA_DIR"
  cd "$DATA_DIR"
  
  echo "Fetching latest dataset manifest..."
  FUNCTION_URL="https://us-west2-data-470400.cloudfunctions.net/generate-download"
  MANIFEST=$(curl -sf "$FUNCTION_URL?format=json" || { echo "Failed to fetch manifest"; exit 1; })
  
  echo "Generating download list for aria2..."
  cat > /tmp/create_list.py <<EOF
import sys, json, os
manifest = json.load(sys.stdin)
with open('aria2-input.txt', 'w') as f:
    for file_info in manifest['files']:
        path = file_info['path']
        url = file_info['url']
        dir_name = os.path.dirname(path)
        file_name = os.path.basename(path)
        f.write(f'{url}\n')
        if dir_name:
            f.write(f'  dir={dir_name}\n')
        f.write(f'  out={file_name}\n')
EOF
  echo "$MANIFEST" | python3 /tmp/create_list.py

  echo "Starting parallel download with aria2c..."
            aria2c -j 16 -x 16 -i aria2-input.txt --continue=true --allow-overwrite=true --auto-file-renaming=false
  echo "Download complete!"
}

mkdir -p "$JOB_DIR"
main 2>&1 | tee "$LOG_FILE"
