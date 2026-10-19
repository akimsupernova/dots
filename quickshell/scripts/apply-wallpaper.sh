#!/usr/bin/env bash
set -u

TYPE="${1:-}"
PATH_IN="${2:-}"
STATE="${XDG_CONFIG_HOME:-$HOME/.config}/wallpaper/current"
LOG="${XDG_RUNTIME_DIR:-/tmp}/apply-wallpaper.log"

log() { printf '%s %s\n' "$(date '+%H:%M:%S')" "$*" >>"$LOG"; }

if [[ -z "$TYPE" || -z "$PATH_IN" ]]; then
  log "usage: apply-wallpaper.sh <image|video> <path>"
  exit 1
fi

if [[ ! -e "$PATH_IN" ]]; then
  log "missing file: $PATH_IN"
  exit 1
fi

mkdir -p "$(dirname "$STATE")"
printf 'type=%s\npath=%s\n' "$TYPE" "$PATH_IN" >"$STATE"

pkill -x mpvpaper 2>/dev/null || true
for _ in 1 2 3 4 5 6; do
  pgrep -x mpvpaper >/dev/null 2>&1 || break
  sleep 0.25
done

case "$TYPE" in
  video)
    log "apply video: $PATH_IN"
    pkill -x awww-daemon 2>/dev/null || true
    pkill -x awww 2>/dev/null || true
    if command -v swww >/dev/null 2>&1; then
      swww kill 2>/dev/null || true
    fi
    sleep 0.2
    if ! command -v mpvpaper >/dev/null 2>&1; then
      log "mpvpaper not found"
      exit 1
    fi
    nohup mpvpaper -o "loop --no-audio --hwdec=auto --profile=low-latency --panscan=1.0 --video-unscaled=no" "*" "$PATH_IN" \
      >>"${XDG_RUNTIME_DIR:-/tmp}/mpvpaper.log" 2>&1 &
    disown || true
    log "mpvpaper started"
    ;;
  image)
    log "apply image: $PATH_IN"
    if ! command -v awww >/dev/null 2>&1; then
      log "awww not found"
      exit 1
    fi

    if ! pgrep -x awww-daemon >/dev/null 2>&1; then
      log "starting awww-daemon"
      awww-daemon >/dev/null 2>&1 &
      disown || true
    fi

    ready=0
    for i in $(seq 1 20); do
      if awww query >/dev/null 2>&1; then
        ready=1
        log "awww-daemon ready after ${i} tries"
        break
      fi
      if ! pgrep -x awww-daemon >/dev/null 2>&1; then
        log "awww-daemon died, restarting"
        awww-daemon >/dev/null 2>&1 &
        disown || true
      fi
      sleep 0.2
    done

    if [[ "$ready" -ne 1 ]]; then
      log "awww-daemon not ready, trying img anyway"
    fi

    sleep 0.2
    awww img "$PATH_IN" --transition-type random --transition-duration 1.0 --transition-fps 60 2>>"$LOG" || true
    log "image applied OK"
    ;;
  *)
    log "unknown type: $TYPE"
    exit 1
    ;;
esac

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if command -v python3 >/dev/null 2>&1; then
  python3 "$SCRIPT_DIR/extract_accent.py" "$PATH_IN" >>"$LOG" 2>&1 &
  disown || true
fi

exit 0
