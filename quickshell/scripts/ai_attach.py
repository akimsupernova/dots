#!/usr/bin/env python3

import base64
import io
import json
import os
import shutil
import subprocess
import sys

MAX_IMAGE_BYTES = 20 * 1024 * 1024
MAX_TEXT_CHARS = 60000
MAX_SIDE = 2048


def out(obj):
    sys.stdout.write(json.dumps(obj, ensure_ascii=False) + "\n")
    sys.exit(0)


def fail(msg):
    out({"ok": False, "error": msg})


def sniff_image(head):
    if head.startswith(b"\x89PNG\r\n\x1a\n"):
        return "png"
    if head.startswith(b"\xff\xd8\xff"):
        return "jpeg"
    if head[:4] == b"RIFF" and head[8:12] == b"WEBP":
        return "webp"
    if head[:6] in (b"GIF87a", b"GIF89a"):
        return "gif"
    if head[:2] == b"BM":
        return "bmp"
    return ""


def image_payload(path, name, data, fmt):
    try:
        from PIL import Image  # optional
    except Exception:
        Image = None

    if Image is not None:
        try:
            im = Image.open(io.BytesIO(data))
            big = max(im.size) > MAX_SIDE
            if fmt not in ("png", "jpeg") or big:
                im.load()
                if big:
                    im.thumbnail((MAX_SIDE, MAX_SIDE))
                buf = io.BytesIO()
                if im.mode in ("RGBA", "LA", "P"):
                    im.convert("RGBA").save(buf, "PNG")
                else:
                    im.convert("RGB").save(buf, "JPEG", quality=90)
                data = buf.getvalue()
        except Exception as e:
            fail("could not read the image: %s" % e)
    elif fmt not in ("png", "jpeg"):
        fail("only PNG and JPEG images are supported (install python-pillow to convert %s)" % fmt.upper())

    out({"ok": True, "kind": "image", "name": name, "bytes": len(data),
         "b64": base64.b64encode(data).decode("ascii")})


def main():
    if len(sys.argv) < 2:
        fail("no file given")
    path = os.path.abspath(os.path.expanduser(sys.argv[1]))
    name = os.path.basename(path)
    if not os.path.exists(path):
        fail("file not found: %s" % path)
    if not os.path.isfile(path):
        fail("%s is not a file" % name)

    try:
        with open(path, "rb") as f:
            head = f.read(4096)
    except OSError as e:
        fail("cannot read %s: %s" % (name, e.strerror or e))

    fmt = sniff_image(head)
    if fmt:
        if os.path.getsize(path) > MAX_IMAGE_BYTES:
            fail("%s is larger than %d MB" % (name, MAX_IMAGE_BYTES // (1024 * 1024)))
        with open(path, "rb") as f:
            image_payload(path, name, f.read(), fmt)

    if head.startswith(b"%PDF"):
        exe = shutil.which("pdftotext")
        if not exe:
            fail("PDF files need pdftotext (sudo pacman -S poppler)")
        try:
            r = subprocess.run([exe, "-layout", "-nopgbrk", "--", path, "-"],
                               capture_output=True, timeout=30)
        except Exception as e:
            fail("pdftotext failed: %s" % e)
        text = r.stdout.decode("utf-8", "replace").strip()
        if not text:
            fail("no text found in %s (a scanned PDF?)" % name)
        trunc = len(text) > MAX_TEXT_CHARS
        out({"ok": True, "kind": "text", "name": name, "text": text[:MAX_TEXT_CHARS], "truncated": trunc})

    if b"\x00" in head:
        fail("%s is a binary file; only text, PDF and image files can be attached" % name)

    try:
        with open(path, "rb") as f:
            raw = f.read(MAX_TEXT_CHARS * 4 + 1)
    except OSError as e:
        fail("cannot read %s: %s" % (name, e.strerror or e))
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        text = raw.decode("utf-8", "ignore")
        if text.count("\ufffd") > 0 or len(text) < len(raw) * 0.6:
            fail("%s does not look like a text file" % name)
    trunc = len(text) > MAX_TEXT_CHARS or os.path.getsize(path) > len(raw)
    out({"ok": True, "kind": "text", "name": name, "text": text[:MAX_TEXT_CHARS], "truncated": trunc})


main()
