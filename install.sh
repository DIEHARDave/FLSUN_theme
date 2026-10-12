#!/bin/bash
# FLSUN_theme installer for the FLSun T1 Pro.
# Run as the pi user from the cloned repo: ~/FLSUN_theme/install.sh
# Safe to re-run, e.g. after a FLSun firmware update.
#
# Mainsail loads its theme from config/.theme. That folder becomes a link to
# this repo's theme/, so updates arrive through the update manager. Whatever
# was in .theme before is moved to ~/printer_data/flsun_theme_backup and put
# back by uninstall.sh.

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HOME}/printer_data/config"
MOONRAKER_CONF="${CONFIG_DIR}/moonraker.conf"
THEME_DIR="${CONFIG_DIR}/.theme"
BACKUP_DIR="${HOME}/printer_data/flsun_theme_backup"

msg() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31mERROR:\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" -ne 0 ] || die "run as the pi user, not root (sudo is used where needed)"
[ -f "$MOONRAKER_CONF" ] || die "$MOONRAKER_CONF not found"

# Clock, certificates and git https support, which updates need; see
# prepare.sh.
"${REPO_DIR}/prepare.sh"

msg "Installing the boot service that sets the clock"
sudo install -m 755 "${REPO_DIR}/system/flsun-timesync" /usr/local/bin/flsun-timesync
sudo install -m 644 "${REPO_DIR}/system/flsun-timesync.service" /etc/systemd/system/flsun-timesync.service
sudo systemctl daemon-reload
sudo systemctl enable flsun-timesync.service > /dev/null 2>&1

msg "Installing the Mainsail theme"
if [ "$(readlink "$THEME_DIR")" = "${REPO_DIR}/theme" ]; then
    echo "    already installed"
else
    if [ -e "$THEME_DIR" ] || [ -L "$THEME_DIR" ]; then
        if [ -d "$BACKUP_DIR" ]; then
            # An older backup is the theme from before the first install
            # (a firmware update may have recreated .theme since); keep it as
            # the one to restore and set this one aside with a date.
            aside="${BACKUP_DIR}/.theme.$(date +%Y%m%d_%H%M%S)"
            mv "$THEME_DIR" "$aside"
            echo "    existing .theme moved to $aside"
        else
            mkdir -p "$BACKUP_DIR"
            mv "$THEME_DIR" "${BACKUP_DIR}/.theme"
            echo "    existing .theme backed up to ${BACKUP_DIR}/.theme"
        fi
    else
        # An empty backup folder records that there was no theme to restore.
        mkdir -p "$BACKUP_DIR"
    fi
    ln -sfn "${REPO_DIR}/theme" "$THEME_DIR"
fi

msg "Adding the update manager entry"
ln -sfn "${REPO_DIR}/moonraker/flsun_theme.conf" "${CONFIG_DIR}/flsun_theme.conf"
if ! grep -q '^\[include flsun_theme\.conf\]' "$MOONRAKER_CONF"; then
    cp "$MOONRAKER_CONF" "${MOONRAKER_CONF}.flsun_theme.bak"
    printf '\n[include flsun_theme.conf]\n' >> "$MOONRAKER_CONF"
fi

msg "Restarting Moonraker"
sudo systemctl restart moonraker

msg "Done. Reload Mainsail in your browser (Ctrl+F5) to see the theme."
