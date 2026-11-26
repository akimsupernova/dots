#!/usr/bin/env bash

find "$HOME/.cache" -mindepth 1 -maxdepth 1 ! -name 'wallpaper-thumbs' -exec rm -rf {} +

pkexec /usr/bin/bash -c '
    pacman -Scc --noconfirm
    rm -rf /var/cache/pacman/pkg
    rm -rf /var/log/journal/*
    rm -rf /root/.cache
    rm -rf /tmp/.*
    rm -rf /tmp/*
'

notify-send -i "$HOME/.config/quickshell/assets/icons/info.svg" "System" "Reboot require"
