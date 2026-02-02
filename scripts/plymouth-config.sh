#!/bin/bash

# Exit on any error
set -e

echo "=== Peitsman Ubuntu Kiosk Plymouth (Boot Logo) Configuration ==="

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

# Logging
LOG_DIR=/var/log/puk
LOG_FILE="$LOG_DIR/plymouth-config.log"
mkdir -p "$LOG_DIR"
touch "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

# Get the current user (who ran sudo)
ACTUAL_USER=${SUDO_USER:-$USER}

LOGO_SRC="/home/$ACTUAL_USER/puk/assets/logo.png"
THEME_DIR="/usr/share/plymouth/themes/puk"
PLYMOUTH_FILE="$THEME_DIR/puk.plymouth"
SCRIPT_FILE="$THEME_DIR/puk.script"

if [ ! -f "$LOGO_SRC" ]; then
    echo "Logo not found: $LOGO_SRC"
    exit 1
fi

mkdir -p "$THEME_DIR"
cp "$LOGO_SRC" "$THEME_DIR/logo.png"

cat > "$SCRIPT_FILE" << 'EOF'
logo_image = Image("logo.png");
screen_width = Window.GetWidth();
screen_height = Window.GetHeight();
logo_width = logo_image.GetWidth();
logo_height = logo_image.GetHeight();

max_width = screen_width * 0.5;
max_height = screen_height * 0.5;
scale_w = max_width / logo_width;
scale_h = max_height / logo_height;
scale = 1.0;
if (scale_w < scale) scale = scale_w;
if (scale_h < scale) scale = scale_h;

logo_sprite = Sprite(logo_image);
logo_sprite.SetScale(scale, scale);

scaled_width = logo_width * scale;
scaled_height = logo_height * scale;
logo_x = (screen_width - scaled_width) / 2;
logo_y = (screen_height - scaled_height) / 2;
logo_sprite.SetPosition(logo_x, logo_y, 0);
EOF

cat > "$PLYMOUTH_FILE" << 'EOF'
[Plymouth Theme]
Name=PUK Boot Logo
Description=PUK custom boot logo
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/puk
ScriptFile=/usr/share/plymouth/themes/puk/puk.script
EOF

update-alternatives --install /usr/share/plymouth/themes/default.plymouth default.plymouth "$PLYMOUTH_FILE" 100
update-alternatives --set default.plymouth "$PLYMOUTH_FILE"

update-initramfs -u

echo "Plymouth boot logo configured."
