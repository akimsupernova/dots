#!/bin/sh

action="$1"
step="${2:-5}"

case "$action" in
    up)   sign=1 ;;
    down) sign=-1 ;;
    get)  sign=0 ;;
    set)  sign=0 ;;
    *) echo "usage: $0 up|down [percent] | get | set <percent>" >&2; exit 2 ;;
esac
case "$step" in
    ''|*[!0-9]*) echo "step must be a number" >&2; exit 2 ;;
esac

BACKLIGHT_DIR="${BACKLIGHT_DIR:-/sys/class/backlight}"
runtime="${XDG_RUNTIME_DIR:-/tmp}"

have() { command -v "$1" >/dev/null 2>&1; }
notify() { have notify-send && notify-send -u low -t 2500 "Brightness" "$1"; return 0; }
osd() { [ -n "${NO_OSD:-}" ] && return 0; have qs && qs ipc call brightness popup "$1" >/dev/null || echo "brightness.sh: qs ipc failed (see: qs ipc show)" >&2; return 0; }

if have flock; then
    exec 9>"$runtime/brightness.lock"
    flock -w 3 9 || exit 0
fi

has_backlight=0
if have brightnessctl && [ -n "$(ls -A "$BACKLIGHT_DIR" 2>/dev/null)" ]; then
    has_backlight=1
fi

buses=""
bus_cache="$runtime/brightness-ddc-bus"
if have ddcutil; then
    buses="${DDC_BUS:-}"
    [ -z "$buses" ] && [ -r "$bus_cache" ] && buses="$(cat "$bus_cache")"
    if [ -z "$buses" ]; then
        buses="$(ddcutil detect --brief 2>/dev/null |
                 awk '/I2C bus:/ { n = $NF; sub(".*i2c-", "", n); printf "%s ", n }')"
        [ -n "$buses" ] && printf '%s\n' "$buses" > "$bus_cache"
    fi
fi

if [ "$has_backlight" -eq 0 ] && [ -z "$buses" ]; then
    notify "No backlight or DDC/CI monitor found (install brightnessctl/ddcutil, enable DDC/CI on the monitor, load i2c-dev module)"
    echo "brightness.sh: no way to control brightness" >&2
    exit 1
fi

ddc_max=100
ddc_cur=""
level_cache="$runtime/brightness-ddc-level"
now="$(date +%s)"
cur=""

if [ "$has_backlight" -eq 1 ]; then
    cur="$(brightnessctl -m -c backlight 2>/dev/null |
           awk -F, 'NR==1 { gsub("%", "", $4); print $4 }')"
fi

if [ -n "$buses" ]; then
    if [ -r "$level_cache" ]; then
        read -r c_ts c_cur c_max < "$level_cache"
        if [ -n "$c_max" ] && [ $((now - c_ts)) -le 3 ]; then
            ddc_cur="$c_cur"; ddc_max="$c_max"
        fi
    fi
    if [ -z "$ddc_cur" ]; then
        first="${buses%% *}"
        vcp="$(ddcutil --bus "$first" --brief getvcp 10 2>/dev/null | awk '/^VCP/ { print $4, $5 }')"
        raw_cur="${vcp% *}"; raw_max="${vcp#* }"
        case "$raw_cur$raw_max" in
            ''|*[!0-9]*) ;;
            *) [ "$raw_max" -gt 0 ] && { ddc_max="$raw_max"; ddc_cur=$((raw_cur * 100 / raw_max)); } ;;
        esac
    fi
    [ -z "$cur" ] && cur="$ddc_cur"
fi

if [ -z "$cur" ]; then
    rm -f "$bus_cache" "$level_cache"
    notify "Failed to read current brightness"
    exit 1
fi

if [ "$action" = get ]; then
    echo "$cur"
    exit 0
fi

if [ "$action" = set ]; then new="$step"; else new=$((cur + sign * step)); fi
[ "$new" -lt 1 ] && new=1
[ "$new" -gt 100 ] && new=100

failed=0

if [ "$has_backlight" -eq 1 ]; then
    for dev in $(brightnessctl -m -c backlight 2>/dev/null | cut -d, -f1); do
        brightnessctl -q -c backlight -d "$dev" set "${new}%" >/dev/null 2>&1 || failed=1
    done
fi

if [ -n "$buses" ]; then
    raw=$((new * ddc_max / 100))
    pids=""
    for bus in $buses; do
        ddcutil --bus "$bus" --noverify setvcp 10 "$raw" >/dev/null 2>&1 &
        pids="$pids $!"
    done
    ddc_failed=0
    for p in $pids; do wait "$p" || ddc_failed=1; done
    if [ "$ddc_failed" -eq 0 ]; then
        printf '%s %s %s\n' "$now" "$new" "$ddc_max" > "$level_cache"
    else
        failed=1
        rm -f "$bus_cache" "$level_cache"
    fi
fi

[ "$failed" -ne 0 ] && notify "Some monitors failed to change brightness"

osd "$new"
[ "$failed" -eq 0 ]
