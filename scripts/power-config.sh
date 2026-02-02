#!/bin/bash

# Exit on any error
set -e

echo "=== Peitsman Ubuntu Kiosk Power Configuration ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# Get the current user (who ran sudo)
ACTUAL_USER=${SUDO_USER:-$USER}
USER_UID=$(id -u "$ACTUAL_USER")
USER_BUS="/run/user/$USER_UID/bus"

# 1) System-wide: prevent sleep/suspend via logind
echo "Configuring systemd-logind to ignore idle/lid actions..."
mkdir -p /etc/systemd
cat > /etc/systemd/logind.conf << 'EOF'
[Login]
HandleLidSwitch=ignore
HandleLidSwitchDocked=ignore
IdleAction=ignore
IdleActionSec=0
EOF

systemctl restart systemd-logind

# 2) GNOME: disable screen blanking and lock (best-effort)
echo "Configuring GNOME power settings for user: $ACTUAL_USER"

if [ -S "$USER_BUS" ]; then
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=$USER_BUS" \
        gsettings set org.gnome.desktop.session idle-delay 0 || true
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=$USER_BUS" \
        gsettings set org.gnome.desktop.screensaver lock-enabled false || true
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=$USER_BUS" \
        gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing' || true
    sudo -u "$ACTUAL_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=$USER_BUS" \
        gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing' || true
else
    echo "Warning: GNOME session bus not found at $USER_BUS"
    echo "Run this script while $ACTUAL_USER is logged in for GNOME settings to apply."
fi

echo "Power configuration complete."
