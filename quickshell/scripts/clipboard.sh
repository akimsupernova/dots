#!/usr/bin/env bash

set -u -o pipefail
umask 077

CACHE_DIR="${XDG_RUNTIME_DIR:-/tmp}/glassveil-clipboard"
MAX_THUMBS=24

need() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'clipboard.sh: missing dependency: %s\n' "$1" >&2
    exit 127
  }
}

valid_id() {
  case "${1:-}" in
    '' | *[!0-9]*) return 1 ;;
  esac
}

cmd="${1:-}"
id="${2:-}"

case "$cmd" in
  list)
    need cliphist
    exec cliphist list
    ;;

  copy)
    need cliphist
    need wl-copy
    valid_id "$id" || exit 2
    printf '%s\t\n' "$id" | cliphist decode | wl-copy
    ;;

  delete)
    need cliphist
    valid_id "$id" || exit 2
    printf '%s\t\n' "$id" | cliphist delete
    rm -f -- "$CACHE_DIR/$id.img"
    ;;

  wipe)
    need cliphist
    cliphist wipe
    rm -rf -- "$CACHE_DIR"
    ;;

  thumbs)
    need cliphist
    mkdir -p "$CACHE_DIR" && chmod 700 "$CACHE_DIR"
    find "$CACHE_DIR" -type f -mmin +120 -delete 2>/dev/null

    count=0
    while IFS=$'\t' read -r entry_id preview; do
      case "$preview" in
        "[[ binary data "*)
          out="$CACHE_DIR/$entry_id.img"
          if [ ! -s "$out" ]; then
            printf '%s\t\n' "$entry_id" | cliphist decode >"$out" 2>/dev/null || rm -f -- "$out"
          fi
          count=$((count + 1))
          [ "$count" -ge "$MAX_THUMBS" ] && break
          ;;
      esac
    done < <(cliphist list)
    ;;

  *)
    printf 'usage: %s {list|copy|delete|wipe|thumbs} [id]\n' "${0##*/}" >&2
    exit 2
    ;;
esac
