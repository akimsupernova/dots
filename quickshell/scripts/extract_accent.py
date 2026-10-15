#!/usr/bin/env python3
import colorsys
import json
import math
import os
import shutil
import subprocess
import sys
import time

SIZE = 48
NEUTRAL = "#cfd3d9"
MIN_LUMINANCE = 0.22
VIDEO_EXT = {".mp4", ".webm", ".mkv", ".mov", ".avi", ".m4v", ".gif"}


def state_file():
    base = os.environ.get("XDG_STATE_HOME") or os.path.join(os.path.expanduser("~"), ".local", "state")
    return os.path.join(base, "quickshell", "accent.json")


def pixels_ffmpeg(path):
    if not shutil.which("ffmpeg"):
        return None
    for seek in (["-ss", "1"], []):
        cmd = ["ffmpeg", "-v", "error", *seek, "-i", path, "-frames:v", "1",
               "-vf", f"scale={SIZE}:{SIZE}:flags=area", "-f", "rawvideo", "-pix_fmt", "rgb24", "-"]
        try:
            out = subprocess.run(cmd, capture_output=True, timeout=30).stdout
        except Exception:
            out = b""
        if len(out) >= SIZE * SIZE * 3:
            return [tuple(out[i:i + 3]) for i in range(0, SIZE * SIZE * 3, 3)]
    return None


def pixels_pillow(path):
    try:
        from PIL import Image
    except ImportError:
        return None
    try:
        with Image.open(path) as im:
            data = im.convert("RGB").resize((SIZE, SIZE), Image.BOX).tobytes()
            return [tuple(data[i:i + 3]) for i in range(0, len(data), 3)]
    except Exception:
        return None


def load_pixels(path):
    is_video = os.path.splitext(path)[1].lower() in VIDEO_EXT
    loaders = [pixels_ffmpeg, pixels_pillow] if is_video else [pixels_pillow, pixels_ffmpeg]
    for loader in loaders:
        px = loader(path)
        if px:
            return px
    return None


def luminance(r, g, b):
    def lin(c):
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)


def to_hex(r, g, b):
    return "#{:02x}{:02x}{:02x}".format(round(r * 255), round(g * 255), round(b * 255))


def pick_accent(px):
    bins = 36
    weight = [0.0] * bins
    sat = [0.0] * bins
    vec_x = [0.0] * bins
    vec_y = [0.0] * bins
    total = 0.0

    for r, g, b in px:
        h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
        if s < 0.18 or v < 0.20:
            continue
        w = (s ** 2) * (0.4 + 0.6 * v)
        i = int(h * bins) % bins
        weight[i] += w
        sat[i] += s * w
        vec_x[i] += math.cos(h * 2 * math.pi) * w
        vec_y[i] += math.sin(h * 2 * math.pi) * w
        total += w

    if total < 1.0:
        return NEUTRAL

    best = max(range(bins), key=lambda i: weight[i] + 0.5 * (weight[i - 1] + weight[(i + 1) % bins]))
    group = [(best - 1) % bins, best, (best + 1) % bins]
    wx = sum(vec_x[i] for i in group)
    wy = sum(vec_y[i] for i in group)
    wsum = sum(weight[i] for i in group)
    hue = (math.atan2(wy, wx) / (2 * math.pi)) % 1.0
    s_mean = sum(sat[i] for i in group) / wsum

    s_out = min(0.85, max(0.45, s_mean * 1.15))
    v_out = 0.95
    r, g, b = colorsys.hsv_to_rgb(hue, s_out, v_out)

    for _ in range(12):
        if luminance(r, g, b) >= MIN_LUMINANCE:
            break
        r, g, b = (c + (1 - c) * 0.08 for c in (r, g, b))
    return to_hex(r, g, b)


def main(argv):
    if "--reset" in argv:
        try:
            os.remove(state_file())
        except FileNotFoundError:
            pass
        return 0

    args = [a for a in argv if not a.startswith("--")]
    if not args:
        print(__doc__, file=sys.stderr)
        return 2
    path = args[0]
    if not os.path.exists(path):
        print(f"file tidak ada: {path}", file=sys.stderr)
        return 1

    px = load_pixels(path)
    if not px:
        print("gagal membaca gambar (pasang python-pillow atau ffmpeg)", file=sys.stderr)
        return 1

    accent = pick_accent(px)
    print(accent)
    if "--print" in argv:
        return 0

    out = state_file()
    os.makedirs(os.path.dirname(out), exist_ok=True)
    payload = json.dumps({"accent": accent, "source": path, "generated": int(time.time())}) + "\n"
    with open(out, "w") as f:
        f.write(payload)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
