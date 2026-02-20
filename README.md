# ubuntu-dashboard-kiosk

Ubuntu kiosk setup scripts for a dashboard PC. This repo configures:
- Autologin (GDM3/LightDM/SDDM)
- Power settings to prevent sleep/lock
- GNOME notifications disabled
- GNOME wallpaper set to `assets/wallpaper.png`
- Plymouth boot logo set to `assets/logo.png`
- Kiosk autostart (browser in kiosk mode)
- Daily shutdown via systemd timer
- Weekly apt update/upgrade (Friday 17:30) via systemd timer

## Requirements
- Ubuntu with systemd
- GNOME recommended (gsettings used for wallpaper/notifications)
- Root access (run setup with `sudo`)

## Quick start
1. Clone or copy this repo to the target machine.
2. Run the setup:

```bash
sudo ./scripts/setup.sh
```

3. Follow the prompts for kiosk URL, browser, fullscreen, and shutdown time.
4. Reboot to verify boot logo and autostart.

## One‑liner install (curl)
If you want a single command without cloning first:

```bash
curl -fsSL https://raw.githubusercontent.com/Peitsman/Peitsman-Ubuntu-Kiosk/main/install.sh | sudo bash
```

## Configuration
Config file is stored at:
```
/home/<user>/puk/config/config.env
```

Example:
```
KIOSK_URL=https://example.com
KIOSK_BROWSER=chromium
KIOSK_FULLSCREEN=true
SHUTDOWN_TIME=18:00
```

Notes:
- `KIOSK_URL` will auto-add `https://` if missing during setup.
- `KIOSK_BROWSER` supported: `chromium`, `firefox`, `chrome`.
- `KIOSK_FULLSCREEN` is stored for future use.
- `SHUTDOWN_TIME` is daily 24h format `HH:MM`.

## What the setup script does
- Detects display manager and configures autologin.
- Downloads repo content to `/home/<user>/puk`.
- Prompts for config and writes `config/config.env`.
- Installs the selected browser (chromium/firefox).
- Applies power configuration to prevent sleep/lock.
- Disables GNOME notifications.
- Sets GNOME wallpaper.
- Replaces Plymouth boot logo.
- Creates autostart to launch the kiosk browser.
- Schedules daily shutdown.
- Schedules weekly apt update/upgrade on Friday at 17:30.

## Files and scripts
- `scripts/setup.sh` main installer
- `scripts/power-config.sh` disables sleep/lock
- `scripts/notifications-config.sh` disables GNOME notifications
- `scripts/wallpaper-config.sh` sets wallpaper
- `scripts/plymouth-config.sh` sets boot logo
- `scripts/kiosk-setup.sh` configures kiosk autostart
- `scripts/shutdown-schedule.sh` schedules daily shutdown
- `scripts/weekly-update-schedule.sh` schedules weekly apt update/upgrade
- `scripts/weekly-update-run.sh` runs apt update/upgrade with logging

## Troubleshooting
- GNOME settings not applied:
  - Run setup while the target user is logged in.
  - The scripts use the user DBUS session.
- Boot logo not changed:
  - Ensure `assets/logo.png` exists.
  - Reboot after setup (initramfs update).
- Browser not found:
  - Chromium/Firefox installs via apt/snap.
  - Chrome must be installed manually.

## Uninstall / rollback (manual)
- Remove autostart: `~/.config/autostart/puk-kiosk.desktop`
- Remove launcher: `~/puk/kiosk-launch.sh`
- Disable shutdown timer:
  - `sudo systemctl disable --now puk-shutdown.timer`
  - delete `/etc/systemd/system/puk-shutdown.timer` and `.service`
  - `sudo systemctl daemon-reload`
- Restore Plymouth theme:
  - `sudo update-alternatives --config default.plymouth`
  - `sudo update-initramfs -u`

## License
Add a license if you want this repo to be reused publicly.
