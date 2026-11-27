#!/usr/bin/env python3

import json
import math
import os
import shutil
import subprocess
import sys
import tempfile

VIDEO_EXT = {".mp4", ".webm", ".mkv", ".mov", ".avi", ".m4v", ".gif"}
WORK_W = 160
MARGIN = 0.04
TOP_INSET = 0.07
CENTER_BIAS = 0.15
STEP = 2


def state_file():
    base = os.environ.get("XDG_STATE_HOME") or os.path.join(os.path.expanduser("~"), ".local", "state")
    d = os.path.join(base, "quickshell")
    os.makedirs(d, exist_ok=True)
    return os.path.join(d, "clock-auto.json")


def monitors():
    try:
        out = subprocess.run(["hyprctl", "monitors", "-j"], capture_output=True, timeout=5).stdout
        data = json.loads(out)
        res = []
        for m in data:
            w, h = m["width"], m["height"]
            if m.get("transform", 0) in (1, 3, 5, 7):
                w, h = h, w
            res.append((m["name"], w, h))
        if res:
            return res
    except Exception:
        pass
    return [("*", 1920, 1080)]


def load_image(path):
    from PIL import Image
    tmp = None
    if os.path.splitext(path)[1].lower() in VIDEO_EXT:
        if not shutil.which("ffmpeg"):
            return None
        tmp = tempfile.NamedTemporaryFile(suffix=".png", delete=False)
        tmp.close()
        for seek in (["-ss", "1"], []):
            subprocess.run(["ffmpeg", "-v", "error", "-y", *seek, "-i", path, "-frames:v", "1", tmp.name],
                           capture_output=True, timeout=30)
            if os.path.getsize(tmp.name) > 0:
                break
        path = tmp.name
    try:
        img = Image.open(path).convert("RGB")
        img.load()
        return img
    finally:
        if tmp:
            os.unlink(tmp.name)


def cover_crop(img, aspect):
    w, h = img.size
    if w / h > aspect:
        nw = int(h * aspect)
        x0 = (w - nw) // 2
        return img.crop((x0, 0, x0 + nw, h))
    nh = int(w / aspect)
    y0 = (h - nh) // 2
    return img.crop((0, y0, w, y0 + nh))


def integral(grid, w, h):
    ii = [[0.0] * (w + 1) for _ in range(h + 1)]
    for y in range(h):
        row = 0.0
        for x in range(w):
            row += grid[y][x]
            ii[y + 1][x + 1] = ii[y][x + 1] + row
    return ii


def box(ii, x0, y0, x1, y1):
    return ii[y1][x1] - ii[y0][x1] - ii[y1][x0] + ii[y0][x0]


def best_spot(img, sw, sh, cw, ch):
    from PIL import Image
    aspect = sw / sh
    img = cover_crop(img, aspect)
    w = WORK_W
    h = max(20, round(w / aspect))
    g = list(img.resize((w, h), Image.BILINEAR).convert("L").tobytes())
    gray = [g[y * w:(y + 1) * w] for y in range(h)]

    edge = [[0.0] * w for _ in range(h)]
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            edge[y][x] = abs(gray[y][x + 1] - gray[y][x - 1]) + abs(gray[y + 1][x] - gray[y - 1][x])

    sq = [[v * v for v in r] for r in gray]
    ie, ig, iq = integral(edge, w, h), integral(gray, w, h), integral(sq, w, h)

    bw = max(4, int(cw * w))
    bh = max(4, int(ch * h))
    x_min, x_max = int(MARGIN * w), int((1 - MARGIN) * w) - bw
    y_min, y_max = int(TOP_INSET * h), int((1 - MARGIN) * h) - bh
    if x_max < x_min:
        x_min = x_max = max(0, (w - bw) // 2)
    if y_max < y_min:
        y_min = y_max = max(0, (h - bh) // 2)

    area = bw * bh
    best, best_cost = ((w - bw) // 2, (h - bh) // 2), float("inf")
    for y in range(y_min, y_max + 1, STEP):
        for x in range(x_min, x_max + 1, STEP):
            x1, y1 = x + bw, y + bh
            mean_e = box(ie, x, y, x1, y1) / area
            mean_g = box(ig, x, y, x1, y1) / area
            var = max(0.0, box(iq, x, y, x1, y1) / area - mean_g * mean_g)
            cost = mean_e + 0.5 * math.sqrt(var)
            dx = (x + bw / 2) / w - 0.5
            dy = (y + bh / 2) / h - 0.5
            cost *= 1 + CENTER_BIAS * math.hypot(dx, dy) * 2
            if cost < best_cost:
                best_cost, best = cost, (x, y)

    return {"cx": round((best[0] + bw / 2) / w, 4), "cy": round((best[1] + bh / 2) / h, 4)}


def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        return 1
    path = args[0]
    cw, ch = 0.26, 0.24
    if "--w" in args:
        cw = float(args[args.index("--w") + 1])
    if "--h" in args:
        ch = float(args[args.index("--h") + 1])
    img = load_image(path)
    if img is None:
        return 1
    result = {name: best_spot(img, w, h, cw, ch) for name, w, h in monitors()}
    with open(state_file(), "w") as f:
        json.dump(result, f)
    return 0


if __name__ == "__main__":
    sys.exit(main())
