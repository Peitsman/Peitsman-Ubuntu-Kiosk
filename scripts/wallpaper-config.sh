#!/bin/bash

# Exit on any error
set -e

echo "=== Peitsman Ubuntu Kiosk Wallpaper Configuration ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# Get the current user (who ran sudo)
ACTUAL_USER=${SUDO_USER:-$USER}
USER_UID=$(id -u "$ACTUAL_USER")
USER_BUS="/run/user/$USER_UID/bus"

WALLPAPER_PATH="/home/$ACTUAL_USER/puk/assets/wallpaper.png"
WALLPAPER_URI="file://$WALLPAPER_PATH"

if [ ! -f "$WALLPAPER_PATH" ]; then
    echo "Wallpaper not found: $WALLPAPER_PATH"
    exit 1
fi

echo "Setting GNOME wallpaper for user: $ACTUAL_USER"

if [ -S "$USER_BUS" ]; then
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=$USER_BUS" \
        gsettings set org.gnome.desktop.background picture-uri "$WALLPAPER_URI" || true
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=$USER_BUS" \
        gsettings set org.gnome.desktop.background picture-uri-dark "$WALLPAPER_URI" || true
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=$USER_BUS" \
        gsettings set org.gnome.desktop.background picture-options "scaled" || true
else
    echo "Warning: GNOME session bus not found at $USER_BUS"
    echo "Run this script while $ACTUAL_USER is logged in for wallpaper to apply."
fi

echo "Wallpaper configuration complete."
