#!/bin/bash

# Exit on any error
set -e

echo "=== Peitsman Ubuntu Kiosk SSH Server Configuration ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# Logging
LOG_DIR=/var/log/puk
LOG_FILE="$LOG_DIR/ssh-server.log"
mkdir -p "$LOG_DIR"
touch "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "Ensuring OpenSSH server is installed..."
if ! dpkg -s openssh-server >/dev/null 2>&1; then
    /usr/bin/apt-get update
    /usr/bin/apt-get install -y openssh-server
fi

echo "Enabling and starting SSH service..."
/bin/systemctl enable --now ssh

echo "SSH server configuration complete."
