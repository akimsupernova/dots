#!/usr/bin/env bash
# Pick a random wallpaper from ~/Pictures/Wallpapers (same folder and file types as the picker)
# and apply it, without opening the wallpaper picker. Never picks the one that is already set.
set -u

DIR="${WALLPAPER_DIR:-$HOME/Pictures/Wallpapers}"
STATE="${XDG_CONFIG_HOME:-$HOME/.config}/wallpaper/current"
APPLY="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/scripts/apply-wallpaper.sh"

notify() { command -v notify-send >/dev/null 2>&1 && notify-send -a Wallpaper "$@"; }

if [[ ! -d "$DIR" ]]; then
  notify "No wallpapers found" "Put images or videos in $DIR"
  exit 1
fi

current=""
if [[ -f "$STATE" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" == path=* ]] && current="${line#path=}"
  done <"$STATE"
fi

mapfile -d '' files < <(find "$DIR" -maxdepth 1 -type f \( \
  -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \
  -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' -o -iname '*.avi' \
  -o -iname '*.m4v' -o -iname '*.gif' \) -print0)

if ((${#files[@]} == 0)); then
  notify "No wallpapers found" "Put images or videos in $DIR"
  exit 1
fi

candidates=()
for f in "${files[@]}"; do
  [[ "$f" == "$current" ]] || candidates+=("$f")
done
((${#candidates[@]} == 0)) && candidates=("${files[@]}")

pick="${candidates[RANDOM % ${#candidates[@]}]}"

case "${pick,,}" in
  *.mp4|*.webm|*.mkv|*.mov|*.avi|*.m4v|*.gif) type=video ;;
  *) type=image ;;
esac

exec bash "$APPLY" "$type" "$pick"
