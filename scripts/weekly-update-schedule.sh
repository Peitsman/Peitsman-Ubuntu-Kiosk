#!/bin/bash

# Exit on any error
set -e

echo "=== Peitsman Ubuntu Kiosk Weekly Update Schedule ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# Logging
LOG_DIR=/var/log/puk
LOG_FILE="$LOG_DIR/weekly-update-schedule.log"
mkdir -p "$LOG_DIR"
touch "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
RUN_SCRIPT="$SCRIPT_DIR/weekly-update-run.sh"

if [ ! -f "$RUN_SCRIPT" ]; then
    echo "Run script not found: $RUN_SCRIPT"
    exit 1
fi

chmod +x "$RUN_SCRIPT"

UNIT_DIR=/etc/systemd/system
SERVICE_FILE="$UNIT_DIR/puk-weekly-update.service"
TIMER_FILE="$UNIT_DIR/puk-weekly-update.timer"

echo "Creating weekly update service: $SERVICE_FILE"
cat > "$SERVICE_FILE" << EOF
[Unit]
Description=PUK weekly apt update and upgrade
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash $RUN_SCRIPT
EOF

echo "Creating weekly update timer: $TIMER_FILE"
cat > "$TIMER_FILE" << 'EOF'
[Unit]
Description=PUK weekly apt update and upgrade timer

[Timer]
OnCalendar=Fri *-*-* 17:30:00
Persistent=true

[Install]
WantedBy=timers.target
EOF

echo "Reloading systemd daemon and enabling timer..."
systemctl daemon-reload
systemctl enable --now puk-weekly-update.timer

echo "Weekly update/upgrade scheduled for every Friday at 17:30."
