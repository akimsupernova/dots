#!/usr/bin/env bash
STATE="${XDG_CONFIG_HOME:-$HOME/.config}/wallpaper/current"
LOG="${XDG_RUNTIME_DIR:-/tmp}/restore-wallpaper.log"
SCRIPT="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/scripts/apply-wallpaper.sh"

log() { printf '%s %s\n' "$(date '+%H:%M:%S')" "$*" >>"$LOG"; }

if [[ ! -f "$STATE" ]]; then
  log "no state file, skip"
  exit 0
fi

type=""
path=""
while IFS= read -r line || [[ -n "$line" ]]; do
  case "$line" in
    type=*) type="${line#type=}" ;;
    path=*) path="${line#path=}" ;;
  esac
done <"$STATE"

if [[ -z "$type" || -z "$path" || ! -e "$path" ]]; then
  log "invalid/missing state type='$type' path='$path'"
  exit 0
fi

sleep 0.5

if [[ -x "$SCRIPT" ]]; then
  log "delegating to apply-wallpaper.sh ($type)"
  exec bash "$SCRIPT" "$type" "$path"
fi

log "apply-wallpaper.sh missing"
exit 1
