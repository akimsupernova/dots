#!/usr/bin/env bash

rm -rf "$HOME/.cache"

pkexec /usr/bin/bash -c '
    pacman -Scc --noconfirm
    rm -rf /var/cache/pacman/pkg
    rm -rf /var/log/journal/*
    rm -rf /root/.cache
    rm -rf /tmp/.*
    rm -rf /tmp/*
'
