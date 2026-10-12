#!/bin/bash
# Removes FLSUN_theme and puts back the .theme and .fluidd-theme folders that
# install.sh backed up, or leaves no theme if there wasn't one.

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HOME}/printer_data/config"
MOONRAKER_CONF="${CONFIG_DIR}/moonraker.conf"
BACKUP_DIR="${HOME}/printer_data/flsun_theme_backup"

msg() { printf '\033[1;32m==>\033[0m %s\n' "$*"; }

[ "$(id -u)" -ne 0 ] || { echo "run as the pi user, not root" >&2; exit 1; }

# Removes the link config/$1 -> repo folder $2 and restores the backup.
remove_theme_dir() {
    local dir="${CONFIG_DIR}/$1" target="${REPO_DIR}/$2"
    if [ "$(readlink "$dir")" = "$target" ]; then
        rm -f "$dir"
    fi
    if [ -e "${BACKUP_DIR}/$1" ] || [ -L "${BACKUP_DIR}/$1" ]; then
        if [ -e "$dir" ] || [ -L "$dir" ]; then
            # Something other than this plugin's link is in place; don't
            # overwrite it.
            echo "    $dir was replaced after install; kept it."
            echo "    The old one is still in ${BACKUP_DIR}/$1"
        else
            mv "${BACKUP_DIR}/$1" "$dir"
            echo "    restored the previous $1"
        fi
    fi
}

msg "Removing the Mainsail theme"
remove_theme_dir .theme theme

msg "Removing the Fluidd theme"
"${REPO_DIR}/fluidd_preset.py" remove
remove_theme_dir .fluidd-theme fluidd

# Leaves the folder if it still holds a backup or a set-aside theme.
[ -d "$BACKUP_DIR" ] && rmdir "$BACKUP_DIR" 2> /dev/null || true

msg "Removing the update manager entry"
sed -i '/^\[include flsun_theme\.conf\]/d' "$MOONRAKER_CONF"
[ -L "${CONFIG_DIR}/flsun_theme.conf" ] && rm -f "${CONFIG_DIR}/flsun_theme.conf"

# The flsun-timesync boot service from prepare.sh is left in place on
# purpose: a correct clock helps everything else on the printer too.

msg "Restarting Moonraker"
sudo systemctl restart moonraker

msg "Done. Delete ~/FLSUN_theme to finish, then reload Mainsail or Fluidd (Ctrl+F5)."
