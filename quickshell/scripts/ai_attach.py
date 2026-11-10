#!/usr/bin/env python3

import base64
import io
import json
import os
import re
import shutil
import subprocess
import sys
import zipfile
import xml.etree.ElementTree as ET

MAX_IMAGE_BYTES = 20 * 1024 * 1024
MAX_TEXT_CHARS = 400000
MAX_SIDE = 2048
MAX_MEMBER_BYTES = 30 * 1024 * 1024


def out(obj):
    sys.stdout.write(json.dumps(obj, ensure_ascii=False) + "\n")
    sys.exit(0)


def fail(msg):
    out({"ok": False, "error": msg})


def text_result(name, text):
    text = text.strip()
    if not text:
        fail("no text found in %s" % name)
    trunc = len(text) > MAX_TEXT_CHARS
    out({"ok": True, "kind": "text", "name": name, "text": text[:MAX_TEXT_CHARS], "truncated": trunc})


def member(zf, name):
    info = zf.getinfo(name)
    if info.file_size > MAX_MEMBER_BYTES:
        raise ValueError("%s is too large inside the file" % name)
    with zf.open(info) as f:
        data = f.read(MAX_MEMBER_BYTES + 1)
    if len(data) > MAX_MEMBER_BYTES:
        raise ValueError("%s is too large inside the file" % name)
    return data


def local(tag):
    return tag.rsplit("}", 1)[-1] if isinstance(tag, str) else ""


def para_text(p):
    parts = []
    def walk(e):
        t = local(e.tag)
        if t in ("t", "delText"):
            parts.append(e.text or "")
        elif t == "tab":
            parts.append("\t")
        elif t in ("br", "cr", "line-break"):
            parts.append("\n")
        elif t == "s":
            try:
                parts.append(" " * int(e.get("{urn:oasis:names:tc:opendocument:xmlns:text:1.0}c", "1")))
            except ValueError:
                parts.append(" ")
        else:
            if e is not p and e.text and t in ("p", "h", "span", "a", "list-item"):
                parts.append(e.text)
        for c in e:
            walk(c)
            if c.tail and t in ("p", "h", "span", "a"):
                parts.append(c.tail)
    if p.text and local(p.tag) in ("p", "h"):
        parts.append(p.text)
    for c in p:
        walk(c)
        if c.tail:
            parts.append(c.tail)
    return "".join(parts)


def paragraphs(root):
    lines = []
    for p in root.iter():
        if local(p.tag) in ("p", "h"):
            lines.append(para_text(p))
    return "\n".join(lines)


def col_index(ref):
    m = re.match(r"([A-Za-z]+)", ref or "")
    if not m:
        return None
    n = 0
    for ch in m.group(1).upper():
        n = n * 26 + (ord(ch) - 64)
    return n - 1


def read_docx(zf):
    parts = []
    for n in ("word/document.xml", "word/footnotes.xml", "word/endnotes.xml"):
        if n in zf.namelist():
            parts.append(paragraphs(ET.fromstring(member(zf, n))))
    return "\n\n".join(x for x in parts if x.strip())


def read_pptx(zf):
    names = zf.namelist()
    def num(n):
        m = re.search(r"(\d+)\.xml$", n)
        return int(m.group(1)) if m else 0
    slides = sorted([n for n in names if re.match(r"ppt/slides/slide\d+\.xml$", n)], key=num)
    notes = {num(n): n for n in names if re.match(r"ppt/notesSlides/notesSlide\d+\.xml$", n)}
    out_parts = []
    for i, n in enumerate(slides, 1):
        txt = paragraphs(ET.fromstring(member(zf, n))).strip()
        block = "--- Slide %d ---\n%s" % (i, txt)
        nn = notes.get(num(n))
        if nn:
            nt = paragraphs(ET.fromstring(member(zf, nn))).strip()
            if nt:
                block += "\n[Notes] " + nt
        out_parts.append(block)
    return "\n\n".join(out_parts)


def read_xlsx(zf):
    names = zf.namelist()
    shared = []
    if "xl/sharedStrings.xml" in names:
        for si in ET.fromstring(member(zf, "xl/sharedStrings.xml")):
            shared.append("".join(t.text or "" for t in si.iter() if local(t.tag) == "t"))
    sheet_names = {}
    try:
        wb = ET.fromstring(member(zf, "xl/workbook.xml"))
        rels = {}
        if "xl/_rels/workbook.xml.rels" in names:
            for r in ET.fromstring(member(zf, "xl/_rels/workbook.xml.rels")):
                rels[r.get("Id")] = r.get("Target")
        for sh in wb.iter():
            if local(sh.tag) == "sheet":
                rid = sh.get("{http://schemas.openxmlformats.org/officeDocument/2006/relationships}id")
                tgt = rels.get(rid, "")
                tgt = tgt.lstrip("/")
                if tgt and not tgt.startswith("xl/"):
                    tgt = "xl/" + tgt
                sheet_names[tgt] = sh.get("name")
    except Exception:
        pass
    sheets = sorted([n for n in names if re.match(r"xl/worksheets/sheet\d+\.xml$", n)],
                    key=lambda n: int(re.search(r"(\d+)\.xml$", n).group(1)))
    blocks, total = [], 0
    for n in sheets:
        rows = []
        for row in ET.fromstring(member(zf, n)).iter():
            if local(row.tag) != "row":
                continue
            cells = {}
            for c in row:
                if local(c.tag) != "c":
                    continue
                t = c.get("t")
                v = None
                for ch in c:
                    if local(ch.tag) == "v":
                        v = ch.text or ""
                    elif local(ch.tag) == "is":
                        v = "".join(x.text or "" for x in ch.iter() if local(x.tag) == "t")
                if v is None:
                    continue
                if t == "s":
                    try:
                        v = shared[int(v)]
                    except (ValueError, IndexError):
                        pass
                elif t == "b":
                    v = "TRUE" if v == "1" else "FALSE"
                idx = col_index(c.get("r"))
                cells[idx if idx is not None else len(cells)] = v.replace("\t", " ").replace("\n", " ")
            if cells:
                line = "\t".join(cells.get(i, "") for i in range(max(cells) + 1))
                rows.append(line)
                total += len(line)
                if total > MAX_TEXT_CHARS:
                    break
        title = sheet_names.get(n) or os.path.basename(n)
        blocks.append("--- Sheet: %s ---\n%s" % (title, "\n".join(rows)))
        if total > MAX_TEXT_CHARS:
            break
    return "\n\n".join(blocks)


def read_odf(zf):
    root = ET.fromstring(member(zf, "content.xml"))
    ns_t = "{urn:oasis:names:tc:opendocument:xmlns:table:1.0}"
    tables = [e for e in root.iter() if e.tag == ns_t + "table"]
    if not tables:
        return paragraphs(root)
    blocks = []
    for tb in tables:
        rows = []
        for row in tb.iter(ns_t + "table-row"):
            cells = []
            for c in row:
                if c.tag not in (ns_t + "table-cell", ns_t + "covered-table-cell"):
                    continue
                txt = " ".join(para_text(p) for p in c.iter() if local(p.tag) in ("p", "h")).strip()
                try:
                    rep = int(c.get(ns_t + "number-columns-repeated", "1"))
                except ValueError:
                    rep = 1
                cells.extend([txt] * (min(rep, 50) if txt else min(rep, 1)))
            while cells and cells[-1] == "":
                cells.pop()
            if cells:
                rows.append("\t".join(cells))
        blocks.append("--- Table: %s ---\n%s" % (tb.get(ns_t + "name", ""), "\n".join(rows)))
    return "\n\n".join(blocks)


def read_rtf(raw):
    s = raw.decode("latin-1")
    skip = {"fonttbl", "colortbl", "stylesheet", "info", "pict", "header", "footer", "themedata", "colorschememapping",
            "datastore", "latentstyles", "generator", "listtable", "listoverridetable", "rsidtbl"}
    out_c, i, n = [], 0, len(s)
    stack, skipping = [], 0
    uc = 1
    while i < n:
        ch = s[i]
        if ch == "{":
            stack.append(skipping)
            i += 1
            if s.startswith("\\*", i):
                skipping = 1
            else:
                m = re.match(r"\\([a-z]+)", s[i:i + 30])
                if m and m.group(1) in skip:
                    skipping = 1
        elif ch == "}":
            skipping = stack.pop() if stack else 0
            i += 1
        elif ch == "\\":
            m = re.match(r"\\([a-zA-Z]+)(-?\d+)? ?", s[i:])
            if m:
                w, arg = m.group(1), m.group(2)
                i += m.end()
                if skipping:
                    continue
                if w in ("par", "line", "sect", "page"):
                    out_c.append("\n")
                elif w == "tab":
                    out_c.append("\t")
                elif w == "u" and arg:
                    v = int(arg)
                    out_c.append(chr(v + 65536 if v < 0 else v))
                    i += uc if i < n and s[i] != "\\" else 0
                elif w == "uc" and arg:
                    uc = int(arg)
            else:
                nxt = s[i + 1:i + 2]
                if nxt == "'":
                    h = s[i + 2:i + 4]
                    i += 4
                    if not skipping:
                        try:
                            out_c.append(bytes([int(h, 16)]).decode("cp1252", "replace"))
                        except ValueError:
                            pass
                else:
                    i += 2
                    if not skipping and nxt in "\\{}":
                        out_c.append(nxt)
        else:
            if not skipping and ch not in "\r\n":
                out_c.append(ch)
            i += 1
    return "".join(out_c)


def try_document(path, name, head):
    if head.startswith(b"{\\rtf"):
        with open(path, "rb") as f:
            raw = f.read(MAX_MEMBER_BYTES)
        text_result(name, read_rtf(raw))
    if head.startswith(b"\xd0\xcf\x11\xe0\xa1\xb1\x1a\xe1"):
        fail("%s is an old binary Office file (.doc/.xls/.ppt). Save it as .docx, .xlsx or .pptx first" % name)
    if not head.startswith(b"PK\x03\x04"):
        return None
    try:
        zf = zipfile.ZipFile(path)
    except Exception:
        return None
    names = zf.namelist()
    try:
        if "word/document.xml" in names:
            text_result(name, read_docx(zf))
        if "ppt/presentation.xml" in names:
            text_result(name, read_pptx(zf))
        if "xl/workbook.xml" in names:
            text_result(name, read_xlsx(zf))
        if "content.xml" in names and "mimetype" in names and member(zf, "mimetype").startswith(b"application/vnd.oasis.opendocument"):
            text_result(name, read_odf(zf))
    except SystemExit:
        raise
    except Exception as e:
        fail("could not read %s: %s" % (name, e))
    fail("%s is a zip archive, not a supported document" % name)


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
        from PIL import Image
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

    try_document(path, name, head)

    if b"\x00" in head:
        fail("%s is a binary file; supported: text, code, PDF, Word/Excel/PowerPoint (.docx .xlsx .pptx), OpenDocument, RTF and images" % name)

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
