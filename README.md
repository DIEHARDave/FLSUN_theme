# FLSUN_theme

The FLSun Mainsail theme for the **FLSun T1 Pro**, installed as a plugin and kept up to date through Mainsail's and Fluidd's update manager.

| File | What it is |
| :--- | :--- |
| `theme/sidebar-logo.png` | Logo at the top of the sidebar |
| `theme/sidebar-background.png` | Sidebar background |
| `theme/main-background.png` | Page background |

Mainsail loads these from the hidden `.theme` folder in the config files. Fluidd keeps its theme elsewhere (`.fluidd-theme`), so it isn't affected.

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

The installer restarts Moonraker (not Klipper, so it's safe during a print). Reload Mainsail in your browser with Ctrl+F5 to see the theme. It is safe to run again, for example after a FLSun firmware update that resets your config.

## Your existing theme

The installer never deletes a theme. If `.theme` already exists, it is moved to `~/printer_data/flsun_theme_backup/.theme` before the plugin's theme goes in, and the uninstaller (or `DISABLE_PLUGIN NAME=flsun_theme`) moves it back.

If you install again later and find a `.theme` that isn't the plugin's (for example after a firmware update), the first backup stays the one that gets restored, and the newer folder is set aside next to it as `.theme.<date>`.

## Files

| Path | What it is |
| :--- | :--- |
| `~/printer_data/config/.theme/` | Link to the theme files in this repo. |
| `~/printer_data/config/flsun_theme.conf` | Link to the update manager entry; included from `moonraker.conf`. |
| `~/printer_data/flsun_theme_backup/` | Your previous theme, if you had one. |

Updates come through Mainsail's and Fluidd's update manager (`flsun_theme`). Don't edit the theme files through the link: an update would refuse to overwrite them. To use your own theme, uninstall the plugin instead.

## Uninstall

```sh
~/FLSUN_theme/uninstall.sh
rm -rf ~/FLSUN_theme
```

This puts your previous theme back, or leaves Mainsail's default look if you didn't have one. The uninstaller keeps the clock-sync service from step 1.

## License

Scripts are licensed under the GNU GPLv3. The theme images come from FLSun's T1 Pro firmware.
