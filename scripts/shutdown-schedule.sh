#!/bin/bash

# Exit on any error
set -e

echo "=== Peitsman Ubuntu Kiosk Shutdown Schedule ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# Logging
LOG_DIR=/var/log/puk
LOG_FILE="$LOG_DIR/shutdown-schedule.log"
mkdir -p "$LOG_DIR"
touch "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

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

if [ -z "$SHUTDOWN_TIME" ]; then
    echo "SHUTDOWN_TIME is empty in config."
    exit 1
fi

if ! echo "$SHUTDOWN_TIME" | grep -qE '^([01][0-9]|2[0-3]):[0-5][0-9]$'; then
    echo "SHUTDOWN_TIME must be in HH:MM (24h) format, e.g. 18:00"
    exit 1
fi

UNIT_DIR=/etc/systemd/system
SERVICE_FILE=$UNIT_DIR/puk-shutdown.service
TIMER_FILE=$UNIT_DIR/puk-shutdown.timer

cat > "$SERVICE_FILE" << 'EOF'
[Unit]
Description=PUK scheduled shutdown

[Service]
Type=oneshot
ExecStart=/sbin/shutdown -h now
EOF

cat > "$TIMER_FILE" << EOF
[Unit]
Description=PUK scheduled shutdown timer

[Timer]
OnCalendar=*-*-* ${SHUTDOWN_TIME}:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload
systemctl enable --now puk-shutdown.timer

echo "Scheduled shutdown set for daily at $SHUTDOWN_TIME"
