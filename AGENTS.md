# Agent Instructions (ubuntu-dashboard-kiosk)

## Repo context
- Target: Ubuntu kiosk setup scripts.
- Primary entrypoint: `scripts/setup.sh`.
- Config file: `config/config.env`.

## Expectations
- Keep scripts POSIX/Bash compatible for Ubuntu.
- Prefer non-interactive flags when possible, but keep prompts in `setup.sh` unless requested otherwise.
- Use absolute paths when changing system settings.
- If adding a new script, wire it into `scripts/setup.sh` and add logging to `/var/log/puk`.

## Logging
- Every script should log to `/var/log/puk/<script>.log` using `tee`.

## Formatting
- Use LF line endings (`.gitattributes` enforces this).
- Keep files ASCII unless non-ASCII is required.

## Safety
- Avoid destructive commands unless explicitly requested.
- For system changes (systemd, plymouth, login manager), leave clear echo messages.

## Update checklist
- If you add config keys, update `config/config.env` and README.
- If you add dependencies, install them in `scripts/setup.sh`.
