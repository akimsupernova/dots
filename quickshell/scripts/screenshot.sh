#!/usr/bin/env bash

set -u -o pipefail

SHOT_DIR="$HOME/Pictures/Screenshots"

notify() {
  command -v notify-send >/dev/null 2>&1 || return 0
  notify-send -a Screenshot \
    -h string:x-canonical-private-synchronous:screenshot "$@"
}

notify_fail() {
  notify -u critical -i dialog-error "Screenshot failed" "$1"
}

shot_area() {
  local geo

  geo="$(slurp)" || exit 0

  if grim -g "$geo" - | wl-copy -t image/png; then
    notify -i camera-photo "Screenshot copied" "Selected area copied to the clipboard"
  else
    notify_fail "Could not capture the selected area"
    exit 1
  fi
}

shot_full() {
  local file

  if ! mkdir -p "$SHOT_DIR"; then
    notify_fail "Could not create $SHOT_DIR"
    exit 1
  fi

  file="$SHOT_DIR/$(date +%F_%H-%M-%S).png"

  if grim "$file" && wl-copy -t image/png < "$file"; then
    notify -i "$file" "Screenshot saved" "$(basename "$file")
Saved in Pictures/Screenshots and copied to the clipboard"
  else
    notify_fail "Could not capture the screen"
    exit 1
  fi
}

case "${1:-}" in
  area) shot_area ;;
  full) shot_full ;;
  *)
    echo "usage: ${0##*/} area|full" >&2
    exit 2
    ;;
esac
