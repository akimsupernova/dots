#!/usr/bin/env bash

set -u -o pipefail

kind="${1:-}"
fallback="${2:-}"

case "$kind" in
  browser) mime="x-scheme-handler/http" ;;
  files)   mime="inode/directory" ;;
  editor)  mime="text/plain" ;;
  image)   mime="image/png" ;;
  video)   mime="video/mp4" ;;
  music)   mime="audio/mpeg" ;;
  pdf)     mime="application/pdf" ;;
  mail)    mime="x-scheme-handler/mailto" ;;
  *)       mime="" ;;
esac

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
  [ -n "$id" ] || return 1
  case "$id" in *.desktop) ;; *) id="$id.desktop" ;; esac

  if command -v gtk-launch >/dev/null 2>&1 && gtk-launch "$id" >/dev/null 2>&1; then
    return 0
  fi
  if command -v gio >/dev/null 2>&1 && path="$(find_desktop_file "$id")"; then
    gio launch "$path" >/dev/null 2>&1 && return 0
  fi
  return 1
}

if [ -n "$mime" ]; then
  id="$(xdg-mime query default "$mime" 2>/dev/null | head -n1)"
  launch_id "$id" && exit 0
fi

if [ -n "$fallback" ]; then
  exec sh -c "$fallback"
fi

command -v notify-send >/dev/null 2>&1 && \
  notify-send -a Keybind -u normal -i dialog-warning \
    "No default app" "Pick one in Settings > Default apps."
exit 1
