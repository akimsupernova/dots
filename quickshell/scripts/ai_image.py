#!/usr/bin/env python3

import base64
import json
import os
import re
import sys
import time
import urllib.error
import urllib.request


def out(obj):
    sys.stdout.write(json.dumps(obj, ensure_ascii=False) + "\n")
    sys.exit(0)


def fail(msg):
    out({"ok": False, "error": msg})


def post(url, body, timeout=900):
    req = urllib.request.Request(url, data=json.dumps(body).encode(),
                                 headers={"Content-Type": "application/json"}, method="POST")
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return json.loads(r.read().decode("utf-8", "replace"))


def find_b64(j):
    if not isinstance(j, dict):
        return ""
    data = j.get("data")
    if isinstance(data, list) and data and isinstance(data[0], dict) and data[0].get("b64_json"):
        return data[0]["b64_json"]
    for k in ("b64_json", "image"):
        if isinstance(j.get(k), str) and j[k]:
            return j[k]
    imgs = j.get("images")
    if isinstance(imgs, list) and imgs and isinstance(imgs[0], str):
        return imgs[0]
    r = j.get("response")
    if isinstance(r, str) and (r.startswith("iVBOR") or r.startswith("/9j/")):
        return r
    return ""


def err_text(e):
    if isinstance(e, urllib.error.HTTPError):
        try:
            j = json.loads(e.read().decode("utf-8", "replace"))
            m = j.get("error")
            if isinstance(m, dict):
                m = m.get("message")
            return "HTTP %d: %s" % (e.code, m or e.reason)
        except Exception:
            return "HTTP %d: %s" % (e.code, e.reason)
    return str(getattr(e, "reason", e))


def main():
    if len(sys.argv) < 4:
        fail("usage: ai_image.py <url> <model> <prompt> [out-dir]")
    base = sys.argv[1].rstrip("/")
    base = re.sub(r"/(api/chat|v1/chat/completions|api/generate)$", "", base)
    model, prompt = sys.argv[2], sys.argv[3]
    outdir = os.path.expanduser(sys.argv[4]) if len(sys.argv) > 4 and sys.argv[4] else \
        os.path.join(os.path.expanduser("~"), "Pictures", "Glassveil")

    b64 = ""
    last = ""
    try:
        b64 = find_b64(post(base + "/v1/images/generations",
                            {"model": model, "prompt": prompt, "response_format": "b64_json"}))
    except Exception as e:
        last = err_text(e)
        if isinstance(e, urllib.error.URLError) and not isinstance(e, urllib.error.HTTPError):
            fail("could not reach Ollama at %s (is it running?)" % base)

    if not b64:
        try:
            b64 = find_b64(post(base + "/api/generate", {"model": model, "prompt": prompt, "stream": False}))
        except Exception as e:
            last = last or err_text(e)

    if not b64:
        fail(last or "the model returned no image (is %s an image generation model?)" % model)

    try:
        raw = base64.b64decode(b64)
    except Exception:
        fail("the model returned data that is not an image")
    ext = "png" if raw.startswith(b"\x89PNG") else ("jpg" if raw.startswith(b"\xff\xd8") else "")
    if not ext:
        fail("the model returned data that is not an image")

    os.makedirs(outdir, exist_ok=True)
    path = os.path.join(outdir, "ai-%s.%s" % (time.strftime("%Y%m%d-%H%M%S"), ext))
    with open(path, "wb") as f:
        f.write(raw)
    out({"ok": True, "path": path})


main()
