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


MAX_BYTES = 8 * 1024 * 1024


def read_request():
    """New mode: one JSON line on stdin (no argv size limit).
    Legacy mode: <ext> <name-hint> <content> on the command line."""
    if len(sys.argv) >= 2 and sys.argv[1] == "--stdin":
        try:
            j = json.loads(sys.stdin.buffer.readline().decode("utf-8"))
        except Exception as e:
            fail("bad request: %s" % e)
        return (str(j.get("ext") or "txt"), str(j.get("base") or ""),
                str(j.get("name") or ""), str(j.get("content") or ""))
    if len(sys.argv) < 4:
        fail("usage: ai_save.py --stdin | <ext> <name-hint> <content>")
    return sys.argv[1], sys.argv[2], "", sys.argv[3]


def main():
    ext, base, name, content = read_request()
    ext = re.sub(r"[^A-Za-z0-9]", "", ext)[:10] or "txt"
    base = re.sub(r"[^A-Za-z0-9._-]", "", base)[:60]
    if not content.strip():
        fail("nothing to save")
    if len(content.encode("utf-8")) > MAX_BYTES:
        fail("this file is larger than %d MB, so it cannot be saved from the panel" % (MAX_BYTES // (1024 * 1024)))
    if not content.endswith("\n"):
        content += "\n"

    folder = downloads_dir()
    try:
        os.makedirs(folder, exist_ok=True)
    except OSError as e:
        fail("cannot create %s: %s" % (folder, e.strerror or e))

    # An explicit file name (from the AI file card) is used as is; only the
    # legacy mode adds the "-edited" suffix.
    clean = re.sub(r"[^A-Za-z0-9._ -]", "_", os.path.basename(name)).strip(" .")[:100]
    if clean:
        stem, dot, suffix = clean.rpartition(".")
        if not dot or not stem:
            stem, suffix = clean, ext
    else:
        stem = (base + "-edited") if base else ("ai-" + time.strftime("%Y%m%d-%H%M%S"))
        suffix = ext
    path = os.path.join(folder, "%s.%s" % (stem, suffix))
    n = 2
    while os.path.exists(path):
        path = os.path.join(folder, "%s-%d.%s" % (stem, n, suffix))
        n += 1
    try:
        with open(path, "w", encoding="utf-8") as f:
            f.write(content)
    except OSError as e:
        fail("cannot write %s: %s" % (path, e.strerror or e))
    out({"ok": True, "path": path, "dir": folder})


main()
