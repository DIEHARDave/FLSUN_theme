#!/bin/bash
# FLSUN_theme installer for the FLSun T1 Pro.
# Run as the pi user from the cloned repo: ~/FLSUN_theme/install.sh
# Safe to re-run, e.g. after a FLSun firmware update.
#
# Mainsail loads its theme from config/.theme and Fluidd from
# config/.fluidd-theme. Those folders become links to this repo's theme/ and
# fluidd/, so updates arrive through the update manager. Whatever was in them
# before is moved to ~/printer_data/flsun_theme_backup and put back by
# uninstall.sh.

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HOME}/printer_data/config"
MOONRAKER_CONF="${CONFIG_DIR}/moonraker.conf"
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

# Links config/$1 to the repo folder $2, first backing up what was there.
install_theme_dir() {
    local dir="${CONFIG_DIR}/$1" target="${REPO_DIR}/$2"
    if [ "$(readlink "$dir")" = "$target" ]; then
        echo "    $1 already installed"
        return
    fi
    mkdir -p "$BACKUP_DIR"
    if [ -e "$dir" ] || [ -L "$dir" ]; then
        if [ -e "${BACKUP_DIR}/$1" ] || [ -L "${BACKUP_DIR}/$1" ]; then
            # The older backup is the theme from before the first install (a
            # firmware update may have recreated the folder since); keep it as
            # the one to restore and set this one aside with a date.
            local aside="${BACKUP_DIR}/$1.$(date +%Y%m%d_%H%M%S)"
            mv "$dir" "$aside"
            echo "    existing $1 moved to $aside"
        else
            mv "$dir" "${BACKUP_DIR}/$1"
            echo "    existing $1 backed up to ${BACKUP_DIR}/$1"
        fi
    fi
    # With nothing backed up, uninstall.sh just removes the link.
    ln -sfn "$target" "$dir"
}

msg "Installing the Mainsail theme"
install_theme_dir .theme theme

msg "Installing the Fluidd theme"
install_theme_dir .fluidd-theme fluidd
# The preset in Settings > Theme. FLSUN_Updater's fluidd hook adds it again
# after each Fluidd update, which replaces config.json.
"${REPO_DIR}/fluidd_preset.py" add

msg "Adding the update manager entry"
ln -sfn "${REPO_DIR}/moonraker/flsun_theme.conf" "${CONFIG_DIR}/flsun_theme.conf"
if ! grep -q '^\[include flsun_theme\.conf\]' "$MOONRAKER_CONF"; then
    cp "$MOONRAKER_CONF" "${MOONRAKER_CONF}.flsun_theme.bak"
    printf '\n[include flsun_theme.conf]\n' >> "$MOONRAKER_CONF"
fi

msg "Restarting Moonraker"
sudo systemctl restart moonraker

msg "Done. Reload Mainsail or Fluidd in your browser (Ctrl+F5). In Fluidd, pick FLSUN in Settings > Theme."
