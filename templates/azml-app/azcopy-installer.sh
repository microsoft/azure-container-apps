#!/bin/bash
 
set -e

# Define download URL
AZCOPY_URL="https://aka.ms/downloadazcopy-v10-linux"

# Create a temporary directory
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

echo "Downloading AzCopy v$AZCOPY_VERSION..."
curl -sL "$AZCOPY_URL" -o azcopy.tar.gz

echo "Extracting AzCopy..."
tar -xf azcopy.tar.gz

# Find the extracted directory
EXTRACTED_DIR=$(find . -type d -name "azcopy_linux_amd64_*" | head -n 1)

if [[ -z "$EXTRACTED_DIR" ]]; then
  echo "Extraction failed. Exiting."
  exit 1
fi

# Move azcopy binary to /usr/local/bin
echo "Installing AzCopy..."
cp "$EXTRACTED_DIR/azcopy" /usr/local/bin/
chmod +x /usr/local/bin/azcopy

# Verify installation
echo "AzCopy installed. Version:"
azcopy --version

# Clean up
cd ~
rm -rf "$TMP_DIR"
