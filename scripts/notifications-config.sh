#!/bin/bash

# Exit on any error
set -e

echo "=== Peitsman Ubuntu Kiosk Notifications Configuration ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# Logging
LOG_DIR=/var/log/puk
LOG_FILE="$LOG_DIR/notifications-config.log"
mkdir -p "$LOG_DIR"
touch "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

# Get the current user (who ran sudo)
ACTUAL_USER=${SUDO_USER:-$USER}
USER_UID=$(id -u "$ACTUAL_USER")
USER_BUS="/run/user/$USER_UID/bus"

echo "Disabling GNOME notifications for user: $ACTUAL_USER"

if [ -S "$USER_BUS" ]; then
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=$USER_BUS" \
        gsettings set org.gnome.desktop.notifications show-banners false || true
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=$USER_BUS" \
        gsettings set org.gnome.desktop.notifications show-in-lock-screen false || true
else
    echo "Warning: GNOME session bus not found at $USER_BUS"
    echo "Run this script while $ACTUAL_USER is logged in for GNOME settings to apply."
fi

echo "Notifications configuration complete."
