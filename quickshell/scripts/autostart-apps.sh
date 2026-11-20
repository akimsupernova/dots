#!/usr/bin/env bash

set -u -o pipefail

LIST="${XDG_CONFIG_HOME:-$HOME/.config}/glassveil/autostart.list"
LOG="${XDG_RUNTIME_DIR:-/tmp}/autostart-apps.log"

log() { printf '%s %s\n' "$(date '+%H:%M:%S')" "$*" >>"$LOG"; }

[ -f "$LIST" ] || { log "no list, skip"; exit 0; }

find_desktop_file() {
  local id="$1" dir
  local IFS=:
  for dir in "${XDG_DATA_HOME:-$HOME/.local/share}" ${XDG_DATA_DIRS:-/usr/local/share:/usr/share}; do
    [ -f "$dir/applications/$id" ] && { printf '%s\n' "$dir/applications/$id"; return 0; }
  done
  return 1
}

launch_id() {
  local id="$1" path
  case "$id" in *.desktop) ;; *) id="$id.desktop" ;; esac

  if command -v gtk-launch >/dev/null 2>&1 && gtk-launch "$id" >/dev/null 2>&1; then
    return 0
  fi
  if command -v gio >/dev/null 2>&1 && path="$(find_desktop_file "$id")"; then
    gio launch "$path" >/dev/null 2>&1 && return 0
  fi
  return 1
}

for _ in $(seq 1 20); do
  pgrep -x quickshell >/dev/null 2>&1 && break
  sleep 0.5
done
sleep 1

while IFS= read -r id || [ -n "$id" ]; do
  id="${id%$'\r'}"
  [ -n "$id" ] || continue
  case "$id" in \#*) continue ;; esac
  case "$id" in *[!A-Za-z0-9._+-]*) log "skip invalid id: $id"; continue ;; esac

  if launch_id "$id"; then
    log "started $id"
  else
    log "failed $id"
  fi
  sleep 0.4
done <"$LIST"
