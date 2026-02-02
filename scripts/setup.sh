#!/bin/bash

# Exit on any error
set -e

echo "=== Peitsman Ubuntu Kiosk Setup (PUK)==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# Logging
LOG_DIR=/var/log/puk
LOG_FILE="$LOG_DIR/setup.log"
mkdir -p "$LOG_DIR"
touch "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

# Get the current user (who ran sudo)
ACTUAL_USER=${SUDO_USER:-$USER}

# Detect display manager
echo "Detecting display manager..."
if systemctl is-active --quiet gdm3; then
    DISPLAY_MANAGER="gdm3"
elif systemctl is-active --quiet lightdm; then
    DISPLAY_MANAGER="lightdm"
elif systemctl is-active --quiet sddm; then
    DISPLAY_MANAGER="sddm"
else
    DISPLAY_MANAGER="unknown"
fi
echo "Display manager: $DISPLAY_MANAGER"

# Configure autologin
echo "Configuring autologin..."
case $DISPLAY_MANAGER in
    "gdm3")
        echo "Configuring GDM3 autologin..."
        mkdir -p /etc/gdm3
        cat > /etc/gdm3/custom.conf << EOF
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=$ACTUAL_USER
EOF
        ;;
    "lightdm")
        echo "Configuring LightDM autologin..."
        mkdir -p /etc/lightdm
        cat > /etc/lightdm/lightdm.conf << EOF
[SeatDefaults]
autologin-user=$ACTUAL_USER
autologin-user-timeout=0
EOF
        ;;
    "sddm")
        echo "Configuring SDDM autologin..."
        mkdir -p /etc/sddm.conf.d
        cat > /etc/sddm.conf.d/autologin.conf << EOF
[Autologin]
User=$ACTUAL_USER
Session=ubuntu.desktop
EOF
        ;;
    *)
        echo "Unknown display manager. Please configure autologin manually."
        ;;
esac

# Ensure git is installed (used to clone repo)
if ! command -v git >/dev/null 2>&1; then
    echo "Installing git..."
    apt-get update
    apt-get install -y git
fi

# Create installation directory
echo "Creating installation directory..."

dir=/home/$ACTUAL_USER/puk
mkdir -p $dir

# Download files from GitHub
echo "Downloading files from GitHub..."
cd /tmp
git clone https://github.com/Peitsman/Peitsman-Ubuntu-Kiosk puk-temp
cp -r puk-temp/* $dir/
cp -r puk-temp/.* $dir/ 2>/dev/null || true
rm -rf puk-temp

# Make scripts executable
echo "Making scripts executable..."
chmod +x $dir/scripts/*.sh

# Ensure config directory exists
mkdir -p $dir/config

# Configure kiosk (prompt for URL and browser, then write config)
echo "Configuring kiosk..."
DEFAULT_CONFIG="$dir/config/config.env"
if [ -f "$DEFAULT_CONFIG" ]; then
    DEFAULT_URL=$(grep -E '^KIOSK_URL=' "$DEFAULT_CONFIG" | head -n 1 | cut -d= -f2-)
    DEFAULT_BROWSER=$(grep -E '^KIOSK_BROWSER=' "$DEFAULT_CONFIG" | head -n 1 | cut -d= -f2-)
    DEFAULT_FULLSCREEN=$(grep -E '^KIOSK_FULLSCREEN=' "$DEFAULT_CONFIG" | head -n 1 | cut -d= -f2-)
    DEFAULT_SHUTDOWN_TIME=$(grep -E '^SHUTDOWN_TIME=' "$DEFAULT_CONFIG" | head -n 1 | cut -d= -f2-)
fi

if [ -z "$DEFAULT_URL" ]; then
    DEFAULT_URL="https://example.com"
fi
if [ -z "$DEFAULT_BROWSER" ]; then
    DEFAULT_BROWSER="chromium"
fi
if [ -z "$DEFAULT_FULLSCREEN" ]; then
    DEFAULT_FULLSCREEN="true"
fi

read -r -p "Kiosk URL [$DEFAULT_URL]: " KIOSK_URL_INPUT
if [ -z "$KIOSK_URL_INPUT" ]; then
    KIOSK_URL_INPUT="$DEFAULT_URL"
fi

if ! echo "$KIOSK_URL_INPUT" | grep -qE '^[a-zA-Z]+://'; then
    KIOSK_URL_INPUT="https://$KIOSK_URL_INPUT"
fi

read -r -p "Kiosk browser (chromium/firefox/chrome) [$DEFAULT_BROWSER]: " KIOSK_BROWSER_INPUT
if [ -z "$KIOSK_BROWSER_INPUT" ]; then
    KIOSK_BROWSER_INPUT="$DEFAULT_BROWSER"
fi

read -r -p "Fullscreen? (true/false) [$DEFAULT_FULLSCREEN]: " KIOSK_FULLSCREEN_INPUT
if [ -z "$KIOSK_FULLSCREEN_INPUT" ]; then
    KIOSK_FULLSCREEN_INPUT="$DEFAULT_FULLSCREEN"
fi

if [ -z "$DEFAULT_SHUTDOWN_TIME" ]; then
    DEFAULT_SHUTDOWN_TIME="18:00"
fi

while true; do
    read -r -p "Daily shutdown time (HH:MM) [$DEFAULT_SHUTDOWN_TIME]: " SHUTDOWN_TIME_INPUT
    if [ -z "$SHUTDOWN_TIME_INPUT" ]; then
        SHUTDOWN_TIME_INPUT="$DEFAULT_SHUTDOWN_TIME"
    fi
    if echo "$SHUTDOWN_TIME_INPUT" | grep -qE '^([01][0-9]|2[0-3]):[0-5][0-9]$'; then
        break
    fi
    echo "Invalid time. Use HH:MM (24h), e.g. 18:00"
done

cat > "$DEFAULT_CONFIG" << EOF
KIOSK_URL=$KIOSK_URL_INPUT
KIOSK_BROWSER=$KIOSK_BROWSER_INPUT
KIOSK_FULLSCREEN=$KIOSK_FULLSCREEN_INPUT
SHUTDOWN_TIME=$SHUTDOWN_TIME_INPUT
EOF

# Install selected browser if missing
echo "Installing browser if needed..."
case "$KIOSK_BROWSER_INPUT" in
    chromium|chromium-browser)
        if ! command -v chromium-browser >/dev/null 2>&1 && ! command -v chromium >/dev/null 2>&1; then
            if command -v snap >/dev/null 2>&1; then
                snap install chromium
            else
                apt-get update
                apt-get install -y chromium-browser || apt-get install -y chromium
            fi
        fi
        ;;
    firefox)
        if ! command -v firefox >/dev/null 2>&1; then
            apt-get update
            apt-get install -y firefox
        fi
        ;;
    chrome|google-chrome)
        if ! command -v google-chrome >/dev/null 2>&1 && ! command -v google-chrome-stable >/dev/null 2>&1; then
            echo "Google Chrome is not installed."
            echo "Please install google-chrome-stable manually or switch to chromium."
            exit 1
        fi
        ;;
    *)
        echo "Unknown browser selection: $KIOSK_BROWSER_INPUT"
        exit 1
        ;;
esac

# Fix ownership - make everything owned by the actual user
echo "Fixing ownership to user: $ACTUAL_USER"
chown -R $ACTUAL_USER:$ACTUAL_USER $dir

# Set proper permissions
echo "Setting proper permissions..."
chmod 755 $dir
chmod 755 $dir/scripts

# Apply power management configuration (prevents sleep/lock)
echo "Applying power configuration..."
bash $dir/scripts/power-config.sh

# Disable notifications
echo "Disabling notifications..."
bash $dir/scripts/notifications-config.sh

# Set wallpaper
echo "Setting wallpaper..."
bash $dir/scripts/wallpaper-config.sh

# Set boot logo (Plymouth)
echo "Setting boot logo..."
bash $dir/scripts/plymouth-config.sh

# Apply kiosk configuration (autostart)
echo "Applying kiosk configuration..."
bash $dir/scripts/kiosk-setup.sh

# Apply daily shutdown schedule
echo "Applying shutdown schedule..."
bash $dir/scripts/shutdown-schedule.sh
