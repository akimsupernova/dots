<p align="center">
  <img src="quickshell/assets/preview/preview1.png" alt="Desktop preview" width="100%">
</p>

## Requirements

- Arch Linux or CachyOS (or a derivative)
- Hyprland already installed, with Lua config support

## Install

```bash
git clone https://github.com/akimsupernova/dots
cd dots
./setup install
```

Useful commands:

```bash
./setup install --no-deps   # dotfiles only, skip packages
./setup install -n          # dry run: show what would happen
./setup welcome             # show the welcome card again at next login
```

## Uninstall

```bash
./setup uninstall
```

Removes the dotfiles and restores your original configs from the backup.
