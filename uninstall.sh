#!/bin/bash
# Removes FLSUN_theme and puts back the .theme folder that install.sh backed
# up, or leaves no theme if there wasn't one.

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HOME}/printer_data/config"
MOONRAKER_CONF="${CONFIG_DIR}/moonraker.conf"
THEME_DIR="${CONFIG_DIR}/.theme"
BACKUP_DIR="${HOME}/printer_data/flsun_theme_backup"

msg() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }

[ "$(id -u)" -ne 0 ] || { echo "run as the pi user, not root" >&2; exit 1; }

msg "Removing the Mainsail theme"
if [ "$(readlink "$THEME_DIR")" = "${REPO_DIR}/theme" ]; then
    rm -f "$THEME_DIR"
fi

if [ -e "${BACKUP_DIR}/.theme" ] || [ -L "${BACKUP_DIR}/.theme" ]; then
    if [ -e "$THEME_DIR" ] || [ -L "$THEME_DIR" ]; then
        # Something other than this plugin's link is in place; don't
        # overwrite it.
        echo "    $THEME_DIR was replaced after install; kept it."
        echo "    The old theme is still in ${BACKUP_DIR}/.theme"
    else
        mv "${BACKUP_DIR}/.theme" "$THEME_DIR"
        echo "    restored the previous theme"
    fi
fi
# Leaves the folder if it still holds a backup or a set-aside theme.
[ -d "$BACKUP_DIR" ] && rmdir "$BACKUP_DIR" 2> /dev/null || true

msg "Removing the update manager entry"
sed -i '/^\[include flsun_theme\.conf\]/d' "$MOONRAKER_CONF"
[ -L "${CONFIG_DIR}/flsun_theme.conf" ] && rm -f "${CONFIG_DIR}/flsun_theme.conf"

# The flsun-timesync boot service from prepare.sh is left in place on
# purpose: a correct clock helps everything else on the printer too.

msg "Restarting Moonraker"
sudo systemctl restart moonraker

msg "Done. Delete ~/FLSUN_theme to finish, then reload Mainsail (Ctrl+F5)."
