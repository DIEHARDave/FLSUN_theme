#!/usr/bin/env python3
"""Adds or removes the FLSUN theme preset in Fluidd's config.json.

    fluidd_preset.py add [FLUIDD_DIR]
    fluidd_preset.py remove [FLUIDD_DIR]

Fluidd lists its theme presets (Settings > Theme) from config.json in its own
folder, which every Fluidd update replaces, so install.sh runs this and
FLSUN_Updater's fluidd hook runs it again after each Fluidd update. "remove"
also switches Fluidd back to its default theme if FLSUN is selected, since
the logo goes away with the plugin.
"""

import json
import os
import sys
import urllib.request

PRESET = {
    "name": "FLSUN",
    # Mainsail's default blue, so both look alike.
    "color": "#2196F3",
    "isDark": True,
    "logo": {"src": "server/files/config/.fluidd-theme/logo_flsun.svg"},
}
DEFAULT_THEME = {
    "color": "#2196F3",
    "isDark": True,
    "logo": {"src": "logo_fluidd.svg"},
}
MOONRAKER = "http://127.0.0.1:7125"


def is_ours(preset):
    return preset.get("name") == PRESET["name"]


def update_config(path, add):
    with open(path) as f:
        config = json.load(f)
    presets = config.setdefault("themePresets", [])
    kept = [p for p in presets if not is_ours(p)]
    if add:
        kept.append(PRESET)
    if kept == presets:
        return False
    config["themePresets"] = kept
    # Rewritten in place, so the file keeps its owner when run as root.
    with open(path, "w") as f:
        json.dump(config, f, indent=2)
        f.write("\n")
    return True


def reset_selected_theme():
    url = "%s/server/database/item?namespace=fluidd&key=uiSettings.theme" % (
        MOONRAKER)
    try:
        with urllib.request.urlopen(url, timeout=5) as r:
            theme = json.load(r)["result"]["value"]
    except Exception:
        return False  # never set, or Moonraker isn't running
    if theme.get("logo", {}).get("src") != PRESET["logo"]["src"]:
        return False
    theme.update(DEFAULT_THEME)
    body = json.dumps({"namespace": "fluidd", "key": "uiSettings.theme",
                       "value": theme}).encode()
    req = urllib.request.Request(
        "%s/server/database/item" % MOONRAKER, data=body, method="POST",
        headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=5):
        pass
    return True


def main():
    if len(sys.argv) not in (2, 3) or sys.argv[1] not in ("add", "remove"):
        sys.exit(__doc__)
    add = sys.argv[1] == "add"
    fluidd_dir = sys.argv[2] if len(sys.argv) == 3 else os.path.expanduser(
        "~/fluidd")
    config = os.path.join(fluidd_dir, "config.json")
    if os.path.isfile(config) and update_config(config, add):
        print("    FLSUN theme preset %s Fluidd" % (
            "added to" if add else "removed from"))
    if not add and reset_selected_theme():
        print("    Fluidd switched back to its default theme")


if __name__ == "__main__":
    main()
