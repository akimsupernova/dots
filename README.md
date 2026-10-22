<p align="center">
  <img src="quickshell/assets/preview/preview1.png" alt="Glassveil Shell desktop preview" width="100%">
</p>

<h1 align="center">Glassveil Shell</h1>

<p align="center">
  A minimal, glassy Hyprland desktop powered by Quickshell.
</p>

<p align="center">
  <code>Arch Linux</code> · <code>Hyprland</code> · <code>Quickshell</code>
</p>

---

## Contents

- [Features](#features)
- [Requirements](#requirements)
- [Install](#install)
- [Key bindings](#key-bindings)
- [AI panel](#ai-panel)
- [Theming](#theming)
- [Wallpaper](#wallpaper)
- [Brightness and volume](#brightness-and-volume)
- [Customization](#customization)
- [Controlling the shell from the terminal](#controlling-the-shell-from-the-terminal)
- [Repository layout](#repository-layout)
- [Troubleshooting](#troubleshooting)
- [Uninstall](#uninstall)
- [License](#license)

## Features

- **Quickshell shell** with a bar, app launcher, sidebar (notifications, Wi-Fi, Bluetooth, calendar, pomodoro), power menu, lock screen, emoji picker, wallpaper picker, monitor settings, cheatsheet, name card, notification popups and volume/brightness OSD.
- **AI panel** (`SUPER + I`) that connects to OpenAI, Claude, Gemini and more with a single `/apikey` command.
- **Wallpaper-driven theme.** The accent color is taken from your wallpaper and applied to the shell, kitty, the fish prompt, GTK 3/4, Qt 5/6 and Kvantum.
- **Image and video wallpapers** (`awww` for images, `mpvpaper` for videos).
- **Hyprland Lua configuration**, split into small modules.
- **Safe installer** that backs up your existing configs and can restore them.

## Requirements

- Arch Linux or a derivative (CachyOS works)
- Hyprland **0.55 or newer** (the config is written in Lua)
- A normal user account with `sudo` (do not run the installer as root)

## Install

```bash
git clone https://github.com/akimsupernova/dots
cd dots
./setup install
```

The installer asks before doing anything risky. In order, it:

1. Offers a full system upgrade (`pacman -Syu`).
2. Installs `yay` if it is missing, then installs all required packages.
3. Offers to enable NetworkManager, Bluetooth and LACT services, and to set up DDC/CI access for monitor brightness (adds you to the `i2c` group).
4. Backs up your existing configs, then copies the dotfiles into place.
5. Sets the default wallpaper and schedules a welcome card for your first login.

After the first login a welcome card appears. Reopen it any time with `SUPER + H`. Press `SUPER + /` to see all key bindings.

### Installer options

```bash
./setup install             # packages + dotfiles
./setup install --no-deps   # dotfiles only, skip packages
./setup install -n          # dry run: show what would happen, change nothing
./setup install -y          # answer yes to everything (--noconfirm); does not reboot
./setup install --reboot    # reboot when finished without asking
./setup install --no-reboot # do not ask about rebooting
./setup deps                # install yay and packages only
./setup welcome             # show the welcome card again at next login
./setup uninstall           # remove the dotfiles and restore your backup
./setup help
```

### Important: files are copied, not linked

`./setup install` **copies** the folders into `~/.config`. Editing files inside the cloned repo does nothing until you run `./setup install` again. To tweak your running system, edit the files in `~/.config` directly and copy changes back to the repo when you are happy.

When you re-run the installer:

- Your original configs are backed up once to `~/.local/share/akim-dotfiles-backup/<timestamp>/`.
- `hypr/modules/monitors.lua` is **kept** (your monitor setup is not overwritten).

### What gets installed where

| Repo folder | Installed to |
| --- | --- |
| `fish`, `gtk-3.0`, `gtk-4.0`, `hypr`, `kitty`, `nwg-look`, `qt5ct`, `qt6ct`, `quickshell` | `~/.config/` |
| `icons` (cursor theme config) | `~/.icons/` |
| `fonts` (Google Sans) | `~/.local/share/fonts/` |

Installer state (manifest, backup location, last command log) lives in `~/.local/state/glassveil-shell/`.

### Packages

The full list is the `PACKAGES` array at the top of [`setup`](setup). In short:

| Group | Packages |
| --- | --- |
| Desktop | `hyprland`, `quickshell`, `hyprsunset`, `xdg-desktop-portal-hyprland`, `xdg-desktop-portal-gtk`, `polkit`, `qt6-wayland`, `qt5-wayland` |
| Wallpaper | `awww`, `mpvpaper`, `ffmpeg`, `python-pillow` |
| Theming | `nwg-look`, `qt5ct`, `qt6ct`, `kvantum`, `kvantum-qt5`, `breeze-icons`, `adwaita-icon-theme`, `bibata-cursor-theme-bin` |
| Fonts | `ttf-jetbrains-mono-nerd`, `noto-fonts`, `noto-fonts-cjk`, `noto-fonts-emoji`, `noto-fonts-extra`, `adwaita-fonts` |
| Audio | `pipewire`, `pipewire-pulse`, `pipewire-alsa`, `wireplumber`, `alsa-utils`, `pavucontrol`, `cava`, `playerctl`, `sof-firmware` |
| Network and devices | `networkmanager`, `bluez`, `bluez-utils`, `upower`, `brightnessctl`, `ddcutil` |
| Tools | `kitty`, `fish`, `btop`, `nvtop`, `lact`, `grim`, `slurp`, `wl-clipboard`, `libnotify`, `python`, `xdg-utils` |
| Apps | `zen-browser-bin`, `dolphin`, `kate`, `konsole`, `ark`, `obs-studio` |

## Key bindings

`SUPER` is the Windows key. Press `SUPER + /` for a live cheatsheet generated from the config.

### Shell

| Keys | Action |
| --- | --- |
| `SUPER` (tap) | App launcher |
| `SUPER + I` | AI panel |
| `SUPER + N` | Sidebar (notifications, quick toggles, pomodoro) |
| `SUPER + R` | Wallpaper picker |
| `SUPER + M` | Monitor settings |
| `SUPER + .` | Emoji picker (click to copy) |
| `SUPER + G` | Name card |
| `SUPER + H` | Welcome card |
| `SUPER + /` | Key binding cheatsheet |
| `SUPER + L` | Lock screen |
| `SUPER + SHIFT + P` | Power menu |

### Apps

| Keys | Action |
| --- | --- |
| `SUPER + Return` | Terminal (kitty) |
| `SUPER + W` | Browser (zen-browser) |
| `SUPER + E` | File manager (dolphin) |
| `SUPER + C` | Editor (kate) |
| `SUPER + X` | Steam |
| `SUPER + O` | OBS Studio |
| `SUPER + A` | Volume control (pavucontrol) |
| `CTRL + SHIFT + ESC` | Task manager (btop in kitty) |

Extra personal app shortcuts (Firefox, Kdenlive, Konsole, DaVinci Resolve) live in [`hypr/custom/keybinds.lua`](hypr/custom/keybinds.lua).

### Windows and workspaces

| Keys | Action |
| --- | --- |
| `SUPER + Q` | Close window |
| `SUPER + F` | Toggle fullscreen |
| `SUPER + V` | Toggle floating |
| `SUPER + P` | Pseudo-tile |
| `SUPER + J` | Toggle split direction |
| `SUPER + arrows` | Move focus |
| `SUPER + 1…0` | Go to workspace 1 to 10 |
| `SUPER + ALT + 1…0` | Move window to workspace 1 to 10 |
| `SUPER + S` | Toggle scratchpad |
| `SUPER + SHIFT + S` | Move window to scratchpad |
| `SUPER + left mouse drag` | Move window |
| `SUPER + right mouse drag` | Resize window |

### Screenshots

| Keys | Action |
| --- | --- |
| `SUPER + SPACE` | Select an area, copy it to the clipboard |
| `ALT + SPACE` | Full screenshot, saved to `~/Pictures/Screenshots` and copied |

### Media

| Keys | Action |
| --- | --- |
| `XF86AudioRaiseVolume` / `XF86AudioLowerVolume` | Volume up / down (2% steps) |
| `XF86MonBrightnessUp` / `XF86MonBrightnessDown` | Brightness up / down |
| `SUPER + mouse wheel` | Volume (scroll up = louder) |
| `SUPER + SHIFT + mouse wheel` | Brightness (scroll up = brighter) |

## AI panel

Press `SUPER + I` for a glass "Ask AI" pill at the bottom of the screen.

Supported providers: **OpenAI, Claude, Gemini, OpenRouter, Groq, DeepSeek, Mistral, xAI** and local **Ollama** (no key needed).

### Getting started

1. Press `SUPER + I`.
2. Type `/apikey openai sk-...` (or `claude`, `gemini`, ...) and press Enter.
3. Ask something.

### Commands

| Command | What it does |
| --- | --- |
| `/apikey` | Show saved keys (masked) |
| `/apikey <provider> <key>` | Save a key and switch to that provider |
| `/apikey remove <provider>` | Delete a saved key |
| `/provider <name>` | Switch provider (or click the provider name in the pill) |
| `/model <name>` | Change the model for the current provider (`/model default` resets it) |
| `/endpoint <provider> <url>` | Use a custom OpenAI-compatible endpoint |
| `/clear` | Start a new chat |
| `/help` | List commands |

Provider aliases: `chatgpt` = openai, `claude` = anthropic, `google` = gemini, `grok` = xai, `local` = ollama.

The **+** button opens a menu with the same actions: new chat, copy the last reply, provider picker, model, API key and help.

### Privacy and security

- Keys are stored in plain text in `~/.config/glassveil/ai.json` with mode `600`. That folder is outside this repository. **Never commit that file.**
- Commands that start with `/` (including your key) are never added to the chat history and never sent to a provider.
- Only the messages you type (up to the last 20 of the current session) and a short system prompt are sent to the provider you selected. The AI cannot read your files, screen, clipboard or run commands.
- Chat history is kept in memory only and disappears when the shell restarts.
- Use `/provider ollama` to keep everything on your own machine.

### Notes

- Default model names change over time. If you get a "model not found" error, set one with `/model <name>`.
- Replies are shown when complete (no streaming yet).
- Attachments (images, files, screenshots) are not supported.

## Theming

The whole desktop follows the **accent color of your wallpaper**.

```text
wallpaper changed
  └─ apply-wallpaper.sh
       └─ extract_accent.py      writes ~/.local/state/quickshell/accent.json
            └─ theme_sync.py     rewrites the themes of the apps below
```

| Target | What is generated |
| --- | --- |
| Quickshell | Reads `accent.json` live (see `quickshell/common/Theme.qml`) |
| kitty | `~/.config/kitty/current-theme.conf` |
| fish | Prompt colors (user, host, current directory) as universal variables, so open terminals update instantly |
| GTK 3 / 4 | `gtk.css` color definitions plus the dark/light preference |
| Qt 5 / 6 | A `glassveil` color scheme for `qt5ct` and `qt6ct` |
| Kvantum | A generated `Glassveil` theme based on an installed Kvantum theme |

Generated files are overwritten on every wallpaper change, so do not edit them by hand.

### Light and dark

`GLASSVEIL_THEME_MODE` (set in `hypr/modules/env.lua`) controls the mode: `auto` (follow the wallpaper), `dark` or `light`.

### Run the sync manually

```bash
python ~/.config/quickshell/scripts/theme_sync.py --from-state          # reuse the last accent
python ~/.config/quickshell/scripts/theme_sync.py --accent "#33ccff"    # force a color
python ~/.config/quickshell/scripts/theme_sync.py --default             # back to the default accent
```

## Wallpaper

- Open the picker with `SUPER + R`.
- Images are set with `awww`, videos (`mp4`, `webm`, `mkv`, `mov`, `gif`, ...) with `mpvpaper`.
- Put your wallpapers in `~/Pictures/Wallpapers` (the default one is copied there on install).
- The current wallpaper is remembered in `~/.config/wallpaper/current` and restored at login.
- Logs: `$XDG_RUNTIME_DIR/apply-wallpaper.log` and `restore-wallpaper.log`.

## Brightness and volume

- **Laptop screens** use `brightnessctl`.
- **External monitors** use DDC/CI through `ddcutil`. The installer offers to load `i2c-dev` at boot and add you to the `i2c` group. **Log out and back in** (or reboot) after that.
- To force a DDC bus: `DDC_BUS=<number>` before running `scripts/brightness.sh`.
- Volume uses `wpctl` (PipeWire). The shell shows an on-screen indicator for both.

## Customization

| I want to... | Edit |
| --- | --- |
| Change default apps (terminal, browser, file manager) | `hypr/modules/programs.lua` |
| Add or change key bindings | `hypr/custom/keybinds.lua` (personal) or `hypr/modules/keybinds.lua` |
| Set up monitors | `hypr/modules/monitors.lua` (kept when you re-run the installer) |
| Change gaps, rounding, blur | `hypr/modules/appearance.lua` |
| Change animations | `hypr/modules/animations.lua` |
| Change keyboard layout, touchpad | `hypr/modules/input.lua` |
| Run programs at startup | `hypr/modules/autostart.lua` |
| Window and layer rules (blur, floating) | `hypr/modules/rules.lua` |
| Change shell size, fonts, glass strength | `quickshell/common/Theme.qml` |
| Change AI providers or default models | `quickshell/services/Ai.qml` |
| Change the terminal font and look | `kitty/kitty.conf` |

Remember: edit in `~/.config/...` for live changes, or edit the repo and run `./setup install --no-deps`.

New layer-shell windows need a rule in `rules.lua` to get blur. Their namespace is set in QML with `WlrLayershell.namespace` (for example `"Glassveil Shell AI"`).

## Controlling the shell from the terminal

Every module can be controlled through Quickshell IPC:

```bash
qs ipc show                       # list all targets and functions
qs ipc call launcher toggle
qs ipc call ai toggle
qs ipc call sidebar toggle
qs ipc call wallpaper toggle
qs ipc call lock lock
```

Available targets: `ai`, `battery`, `brightness`, `cheatsheet`, `clock`, `emoji`, `launcher`, `lock`, `monitor`, `namecard`, `notifications`, `pomodoro`, `power`, `sidebar`, `wallpaper`, `welcome`. Run `qs ipc show` to see the functions each one offers.

## Repository layout

```text
.
├── setup                     installer / uninstaller
├── hypr/
│   ├── hyprland.lua          entry point, loads the modules below
│   ├── modules/              appearance, animations, input, keybinds, rules, ...
│   └── custom/keybinds.lua   your personal key bindings
├── quickshell/
│   ├── shell.qml             root, loads every module
│   ├── common/               shared parts (Theme, GlassPanel, Icon, buttons, ...)
│   ├── services/             state and backends (Network, Notifs, Ai, Brightness, ...)
│   ├── modules/              one folder per feature (bar, launcher, sidebar, ai, osd, ...)
│   ├── scripts/              wallpaper, brightness, accent extraction, theme sync
│   └── assets/               icons, wallpaper, emoji list, previews
├── kitty/  fish/  gtk-3.0/  gtk-4.0/  qt5ct/  qt6ct/  nwg-look/
├── icons/                    cursor theme config
└── fonts/                    Google Sans
```

## Troubleshooting

**The installer fails.** It prints the failing step, the last lines of output and common fixes (locked database, conflicts, keyring, mirrors, AUR builds). The full log of the last command is in `~/.local/state/glassveil-shell/last-command.log`. Fix the problem and run `./setup install` again; it is safe to repeat. If you installed the packages yourself, use `./setup install --no-deps`.

**Hyprland shows a config error.** Check your version with `Hyprland --version`; it must be 0.55 or newer.

**The shell does not start or looks broken.** Run `quickshell` in a terminal to see the errors. After editing files, restart it with `pkill quickshell; quickshell &`.

**`qs ipc call ...` does nothing.** Make sure the shell is running, then check the target name with `qs ipc show`.

**Emoji or some fonts do not show.** Run `fc-cache -f` and make sure `noto-fonts-emoji` and `noto-fonts-cjk` are installed.

**Brightness keys do nothing on an external monitor.** Your monitor must support DDC/CI (enable it in the monitor's own menu). Make sure you are in the `i2c` group (`id`) and have logged in again since the install.

**Wi-Fi or Bluetooth menus are empty.** They need `NetworkManager` and `bluetooth` services: `sudo systemctl enable --now NetworkManager bluetooth`.

**The wallpaper does not change or colors do not update.** Check `$XDG_RUNTIME_DIR/apply-wallpaper.log`, and run `theme_sync.py --from-state` by hand to see errors.

**The AI panel says "model not found".** Set a current model with `/model <name>`. Check your provider's documentation for model names.

## Uninstall

```bash
./setup uninstall
```

Removes the installed dotfiles and restores your previous configuration from the backup. Files the installer did not create are left alone.

## License

[GNU General Public License v3.0](LICENSE)
