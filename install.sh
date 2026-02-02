#!/bin/bash

# Exit on any error
set -e

REPO_URL="https://github.com/Peitsman/Peitsman-Ubuntu-Kiosk"
TARGET_DIR="/tmp/puk-install"

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

if ! command -v git >/dev/null 2>&1; then
    echo "Installing git..."
    apt-get update
    apt-get install -y git
fi

echo "Cloning repo..."
rm -rf "$TARGET_DIR"
git clone "$REPO_URL" "$TARGET_DIR"

echo "Running setup..."
if [ -t 0 ]; then
    bash "$TARGET_DIR/scripts/setup.sh"
else
    if [ -r /dev/tty ]; then
        bash "$TARGET_DIR/scripts/setup.sh" </dev/tty
    else
        echo "No TTY available for interactive prompts."
        echo "Run: sudo $TARGET_DIR/scripts/setup.sh"
        exit 1
    fi
fi
