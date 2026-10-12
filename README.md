# FLSUN_theme

The FLSun theme for Mainsail and Fluidd on the **FLSun T1 Pro**, installed as a plugin and kept up to date through Mainsail's and Fluidd's update manager.

| File | What it is |
| :--- | :--- |
| `theme/sidebar-logo.png` | Logo at the top of the sidebar |
| `theme/sidebar-background.png` | Sidebar background |
| `theme/main-background.png` | Page background |

Mainsail loads these from the hidden `.theme` folder in the config files and uses them straight away.

Fluidd gets a theme called **FLSUN** that uses the same images: pick it in Fluidd's **Settings > Theme**. It shows the FLSun logo in the top bar, with the same page and sidebar backgrounds as Mainsail. The files are in `fluidd/`:

| File | What it is |
| :--- | :--- |
| `fluidd/logo_flsun.svg` | The logo for the FLSUN preset; it shows `theme/sidebar-logo.png` |
| `fluidd/custom.css` | Puts `theme/main-background.png` and `theme/sidebar-background.png` behind the page and the sidebar |

Fluidd lists its theme presets from `config.json` in its own folder (`~/fluidd`), and every Fluidd update replaces that file. With [FLSUN_Updater](https://github.com/DIEHARDave/FLSUN_Updater) managing Fluidd, the FLSUN preset is added back after each update. Otherwise, run `~/FLSUN_theme/fluidd_preset.py add` after updating Fluidd. The background images apply even without the preset.

## Install

If you use [FLSUN_Updater](https://github.com/DIEHARDave/FLSUN_Updater), set `flsun_theme: yes` in `flsun_plugins.cfg`, or run `ENABLE_PLUGIN NAME=flsun_theme` in the console.

To install by hand, SSH into the printer as `pi` (the default password is `1`).

1. Prepare the system. FLSun's system image can't reach GitHub as shipped: the clock starts about a year and a half in the past, the certificate links are missing, and git's https support was removed. These commands fix all three (skip them if another FLSUN_ plugin is already installed, since each of them makes the same fixes):

   ```sh
   sudo ntpdate -u -b time.google.com
   curl -fsSL --cacert /etc/ssl/certs/ca-certificates.crt https://raw.githubusercontent.com/DIEHARDave/FLSUN_theme/main/prepare.sh | bash
   ```

   Don't use `timedatectl set-ntp true`: on this image it stops the time service rather than starting it.

2. Download and install the plugin:

   ```sh
   cd ~
   git clone https://github.com/DIEHARDave/FLSUN_theme.git
   ~/FLSUN_theme/install.sh
   ```

The installer restarts Moonraker (not Klipper, so it's safe during a print). Reload Mainsail or Fluidd in your browser with Ctrl+F5 to see the theme. It is safe to run again, for example after a FLSun firmware update that resets your config.

## Your existing theme

The installer never deletes a theme. If `.theme` or `.fluidd-theme` already exists, it is moved to `~/printer_data/flsun_theme_backup/` before the plugin's theme goes in, and the uninstaller (or `DISABLE_PLUGIN NAME=flsun_theme`) moves it back. The uninstaller also removes the FLSUN preset from Fluidd and, if it was selected, switches Fluidd back to its default theme.

If you install again later and find a theme folder that isn't the plugin's (for example after a firmware update), the first backup stays the one that gets restored, and the newer folder is set aside next to it with the date added to its name.

## Files

| Path | What it is |
| :--- | :--- |
| `~/printer_data/config/.theme/` | Link to the Mainsail theme files in this repo (`theme/`). |
| `~/printer_data/config/.fluidd-theme/` | Link to the Fluidd theme files in this repo (`fluidd/`). |
| `~/fluidd/config.json` | Gets the FLSUN preset added to its `themePresets`. |
| `~/printer_data/config/flsun_theme.conf` | Link to the update manager entry; included from `moonraker.conf`. |
| `~/printer_data/flsun_theme_backup/` | Your previous theme folders, if you had any. |

Updates come through Mainsail's and Fluidd's update manager (`flsun_theme`). Don't edit the theme files through the link: an update would refuse to overwrite them. To use your own theme, uninstall the plugin instead.

## Uninstall

```sh
~/FLSUN_theme/uninstall.sh
rm -rf ~/FLSUN_theme
```

This puts your previous themes back, or leaves Mainsail's and Fluidd's default look if you didn't have one. The uninstaller keeps the clock-sync service from step 1.

## License

Scripts are licensed under the GNU GPLv3. The theme images come from FLSun's T1 Pro firmware.
