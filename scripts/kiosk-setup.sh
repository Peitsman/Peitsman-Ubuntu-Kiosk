#!/bin/bash

# Exit on any error
set -e

echo "=== Peitsman Ubuntu Kiosk Configuration ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# Logging
LOG_DIR=/var/log/puk
LOG_FILE="$LOG_DIR/kiosk-setup.log"
mkdir -p "$LOG_DIR"
touch "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

# Get the current user (who ran sudo)
ACTUAL_USER=${SUDO_USER:-$USER}
HOME_DIR=/home/$ACTUAL_USER

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
CONFIG_FILE="$SCRIPT_DIR/../config/config.env"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Config not found: $CONFIG_FILE"
    exit 1
fi

# Load config
set -a
. "$CONFIG_FILE"
set +a

if [ -z "$KIOSK_URL" ]; then
    echo "KIOSK_URL is empty in config."
    exit 1
fi

case "$KIOSK_BROWSER" in
    chromium|chromium-browser)
        BINARY=$(command -v chromium-browser || command -v chromium || command -v google-chrome || command -v google-chrome-stable || true)
        BROWSER_ARGS="--kiosk --incognito --disable-infobars --disable-session-crashed-bubble --noerrdialogs --disable-restore-session-state"
        ;;
    chrome|google-chrome)
        BINARY=$(command -v google-chrome || command -v google-chrome-stable || true)
        BROWSER_ARGS="--kiosk --incognito --disable-infobars --disable-session-crashed-bubble --noerrdialogs --disable-restore-session-state"
        ;;
    firefox)
        BINARY=$(command -v firefox || true)
        BROWSER_ARGS="--kiosk"
        ;;
    *)
        echo "Unknown KIOSK_BROWSER: $KIOSK_BROWSER"
        exit 1
        ;;
esac

if [ -z "$BINARY" ]; then
    echo "Browser binary not found for: $KIOSK_BROWSER"
    exit 1
fi

# Ensure cursor auto-hide is available
if ! command -v unclutter-xfixes >/dev/null 2>&1; then
    echo "Installing unclutter-xfixes..."
    apt-get update
    apt-get install -y unclutter-xfixes
fi

LAUNCHER="$HOME_DIR/puk/kiosk-launch.sh"
AUTOSTART_DIR="$HOME_DIR/.config/autostart"
AUTOSTART_FILE="$AUTOSTART_DIR/puk-kiosk.desktop"
CURSOR_AUTOSTART_FILE="$AUTOSTART_DIR/puk-hide-cursor.desktop"

mkdir -p "$AUTOSTART_DIR"

cat > "$LAUNCHER" << EOF
#!/bin/bash
exec "$BINARY" $BROWSER_ARGS "$KIOSK_URL"
EOF

chmod +x "$LAUNCHER"
chown "$ACTUAL_USER:$ACTUAL_USER" "$LAUNCHER"

cat > "$AUTOSTART_FILE" << EOF
[Desktop Entry]
Type=Application
Name=PUK Kiosk
Exec=$LAUNCHER
X-GNOME-Autostart-enabled=true
Terminal=false
NoDisplay=true
EOF

chown "$ACTUAL_USER:$ACTUAL_USER" "$AUTOSTART_FILE"

cat > "$CURSOR_AUTOSTART_FILE" << 'EOF'
[Desktop Entry]
Type=Application
Name=PUK Hide Cursor
Exec=unclutter-xfixes --timeout 1 --hide-on-touch --start-hidden
X-GNOME-Autostart-enabled=true
Terminal=false
NoDisplay=true
EOF

chown "$ACTUAL_USER:$ACTUAL_USER" "$CURSOR_AUTOSTART_FILE"

echo "Kiosk autostart configured for user: $ACTUAL_USER"
