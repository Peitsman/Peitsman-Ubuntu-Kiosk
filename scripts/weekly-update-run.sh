#!/bin/bash

# Exit on any error
set -e

echo "=== Peitsman Ubuntu Kiosk Weekly Update Run ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# Logging
LOG_DIR=/var/log/puk
LOG_FILE="$LOG_DIR/weekly-update-run.log"
mkdir -p "$LOG_DIR"
touch "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Starting apt update..."
/usr/bin/apt-get update

echo "Starting apt upgrade..."
/usr/bin/apt-get -y upgrade

echo "Weekly update run complete."
