#!/usr/bin/env python3
import json
import os
import re
import sys
import time


def out(obj):
    sys.stdout.write(json.dumps(obj, ensure_ascii=False) + "\n")
    sys.exit(0)


def fail(msg):
    out({"ok": False, "error": msg})


def downloads_dir():
    home = os.path.expanduser("~")
    cfg = os.path.join(os.environ.get("XDG_CONFIG_HOME") or os.path.join(home, ".config"), "user-dirs.dirs")
    try:
        with open(cfg, encoding="utf-8") as f:
            for line in f:
                m = re.match(r'\s*XDG_DOWNLOAD_DIR\s*=\s*"?([^"\n]+)"?', line)
                if m:
                    return m.group(1).replace("$HOME", home)
    except OSError:
        pass
    return os.path.join(home, "Downloads")


def main():
    if len(sys.argv) < 4:
        fail("usage: ai_save.py <ext> <name-hint> <content>")
    ext = re.sub(r"[^A-Za-z0-9]", "", sys.argv[1])[:10] or "txt"
    base = re.sub(r"[^A-Za-z0-9._-]", "", sys.argv[2])[:60]
    content = sys.argv[3]
    if not content.strip():
        fail("nothing to save")
    if len(content.encode("utf-8")) > 120000:
        fail("this is too long to save from the panel. Use Copy instead.")
    if not content.endswith("\n"):
        content += "\n"

    folder = downloads_dir()
    try:
        os.makedirs(folder, exist_ok=True)
    except OSError as e:
        fail("cannot create %s: %s" % (folder, e.strerror or e))

    stem = (base + "-edited") if base else ("ai-" + time.strftime("%Y%m%d-%H%M%S"))
    path = os.path.join(folder, "%s.%s" % (stem, ext))
    n = 2
    while os.path.exists(path):
        path = os.path.join(folder, "%s-%d.%s" % (stem, n, ext))
        n += 1
    try:
        with open(path, "w", encoding="utf-8") as f:
            f.write(content)
    except OSError as e:
        fail("cannot write %s: %s" % (path, e.strerror or e))
    out({"ok": True, "path": path, "dir": folder})


main()
