#!/usr/bin/env python3
"""Streaming helper for the AI panel.

Reads ONE line of JSON from stdin:
  {"kind": "openai|anthropic|gemini|ollama", "url": str, "headers": {...},
   "body": {...}, "connect_timeout": 30, "idle_timeout": 900}

Writes one JSON object per line to stdout:
  {"t": "text",  "d": "..."}                       answer text
  {"t": "think", "d": "..."}                       reasoning text (never part of the answer)
  {"t": "calls", "calls": [...]}                   tool calls (ollama)
  {"t": "end",   "reason": "stop|length|eof|..."}  stream finished
  {"t": "error", "status": int, "msg": "..."}      request failed (terminal)

The idle timeout only fires when the server sends nothing at all for that long,
so long generations never time out as long as tokens keep flowing.
"""
import http.client
import json
import re
import socket
import ssl
import sys
from urllib.parse import urlsplit

TAGS = ("think", "thinking", "reasoning")


def emit(obj):
    try:
        sys.stdout.write(json.dumps(obj, ensure_ascii=False) + "\n")
        sys.stdout.flush()
    except (BrokenPipeError, OSError):
        sys.exit(0)


def die(status, msg):
    emit({"t": "error", "status": status, "msg": str(msg)})
    sys.exit(0)


def err_text(raw):
    """Pull a readable message out of a provider error body."""
    try:
        j = json.loads(raw)
    except Exception:
        return raw.decode("utf-8", "replace").strip()[:400]
    if isinstance(j, list) and j:
        j = j[0]
    e = j.get("error", j) if isinstance(j, dict) else j
    if isinstance(e, dict):
        e = e.get("message") or e.get("error") or json.dumps(e)
    return str(e)[:600]


class ThinkFilter:
    """Moves <think>...</think> style blocks out of the answer stream."""

    def __init__(self):
        self.buf = ""
        self.close = None  # closing tag while inside a reasoning block
        self.lead = False  # strip newlines right after a closing tag

    @staticmethod
    def partial(low, tags):
        """Length of the longest suffix of `low` that is a proper prefix of a tag."""
        best = 0
        for t in tags:
            for n in range(min(len(t) - 1, len(low)), 0, -1):
                if low.endswith(t[:n]):
                    best = max(best, n)
                    break
        return best

    def _text(self, out, s):
        if self.lead:
            s = s.lstrip("\n")
            if s:
                self.lead = False
        if s:
            out.append(("text", s))

    def feed(self, s, final=False):
        out = []
        self.buf += s
        while True:
            if self.close is None:
                m = re.search(r"<(think|thinking|reasoning)>", self.buf, re.I)
                if m:
                    self._text(out, self.buf[:m.start()])
                    self.close = "</%s>" % m.group(1).lower()
                    self.buf = self.buf[m.end():]
                    continue
                keep = 0 if final else self.partial(self.buf.lower(), ["<%s>" % t for t in TAGS])
                cut = len(self.buf) - keep
                self._text(out, self.buf[:cut])
                self.buf = self.buf[cut:]
                break
            i = self.buf.lower().find(self.close)
            if i >= 0:
                if i > 0:
                    out.append(("think", self.buf[:i]))
                self.buf = self.buf[i + len(self.close):]
                self.close = None
                self.lead = True
                continue
            keep = 0 if final else self.partial(self.buf.lower(), [self.close])
            cut = len(self.buf) - keep
            if cut > 0:
                out.append(("think", self.buf[:cut]))
            self.buf = self.buf[cut:]
            break
        if final and self.buf:
            out.append(("think" if self.close else "text", self.buf))
            self.buf = ""
        return out


class Stream:
    def __init__(self, kind):
        self.kind = kind
        self.filter = ThinkFilter()
        self.reason = ""
        self.calls = []
        self.done = False

    def text(self, s, final=False):
        if not isinstance(s, str):
            return
        for kind, d in self.filter.feed(s, final):
            emit({"t": kind, "d": d})

    def think(self, s):
        if isinstance(s, str) and s:
            emit({"t": "think", "d": s})

    # ---- per-provider line handlers -------------------------------------
    def line(self, ln):
        if self.kind == "ollama":
            return self.ollama(ln)
        if not ln.startswith("data:"):
            return
        payload = ln[5:].strip()
        if payload == "[DONE]":
            self.done = True
            return
        try:
            j = json.loads(payload)
        except Exception:
            return
        if self.kind == "anthropic":
            self.anthropic(j)
        elif self.kind == "gemini":
            self.gemini(j)
        else:
            self.openai(j)

    def openai(self, j):
        if isinstance(j, dict) and j.get("error"):
            e = j["error"]
            die(0, (e.get("message") if isinstance(e, dict) else e) or "provider error")
        ch = ((j.get("choices") or [{}])[0]) if isinstance(j, dict) else {}
        d = ch.get("delta") or {}
        self.think(d.get("reasoning_content") or d.get("reasoning"))
        self.text(d.get("content"))
        fr = ch.get("finish_reason")
        if fr:
            self.reason = {"length": "length", "stop": "stop"}.get(fr, fr)

    def anthropic(self, j):
        t = j.get("type")
        if t == "content_block_delta":
            d = j.get("delta") or {}
            if d.get("type") == "text_delta":
                self.text(d.get("text"))
            elif d.get("type") == "thinking_delta":
                self.think(d.get("thinking"))
        elif t == "message_delta":
            sr = (j.get("delta") or {}).get("stop_reason")
            if sr:
                self.reason = {"max_tokens": "length", "end_turn": "stop"}.get(sr, sr)
        elif t == "error":
            e = j.get("error") or {}
            die(0, e.get("message") or "provider error")

    def gemini(self, j):
        pf = j.get("promptFeedback") or {}
        if pf.get("blockReason"):
            die(0, "blocked by Gemini: %s" % pf["blockReason"])
        for c in j.get("candidates") or []:
            for p in (c.get("content") or {}).get("parts") or []:
                if p.get("thought") is True:
                    self.think(p.get("text"))
                elif "text" in p:
                    self.text(p.get("text"))
            fr = c.get("finishReason")
            if fr:
                self.reason = {"MAX_TOKENS": "length", "STOP": "stop"}.get(fr, fr.lower())

    def ollama(self, ln):
        if not ln:
            return
        try:
            j = json.loads(ln)
        except Exception:
            return
        if j.get("error"):
            die(0, j["error"])
        m = j.get("message") or {}
        self.think(m.get("thinking"))
        self.text(m.get("content"))
        if m.get("tool_calls"):
            self.calls.extend(m["tool_calls"])
        if j.get("done"):
            self.done = True
            self.reason = j.get("done_reason") or "stop"

    def finish(self):
        self.text("", final=True)
        if self.calls:
            emit({"t": "calls", "calls": self.calls})
        reason = self.reason
        if not reason:
            reason = "stop" if self.done else "eof"
        emit({"t": "end", "reason": reason})


def main():
    try:
        spec = json.loads(sys.stdin.buffer.readline().decode("utf-8"))
        kind = spec["kind"]
        url = spec["url"]
    except Exception as e:
        die(0, "bad request: %s" % e)

    headers = dict(spec.get("headers") or {})
    headers.setdefault("User-Agent", "glassveil-ai/2.0")
    if kind != "ollama":
        headers["Accept"] = "text/event-stream"
    body = json.dumps(spec.get("body") or {}).encode("utf-8")
    connect_t = float(spec.get("connect_timeout", 30))
    idle_t = float(spec.get("idle_timeout", 900))

    u = urlsplit(url)
    if u.scheme not in ("http", "https") or not u.hostname:
        die(0, "invalid URL: %s" % url)
    path = (u.path or "/") + ("?" + u.query if u.query else "")

    try:
        if u.scheme == "https":
            conn = http.client.HTTPSConnection(u.hostname, u.port, timeout=connect_t,
                                               context=ssl.create_default_context())
        else:
            conn = http.client.HTTPConnection(u.hostname, u.port, timeout=connect_t)
        conn.connect()
        conn.sock.settimeout(idle_t)
        conn.request("POST", path, body=body, headers=headers)
        resp = conn.getresponse()
    except socket.timeout:
        die(0, "timed out while connecting to %s" % u.hostname)
    except ConnectionRefusedError:
        die(0, "connection refused by %s" % (u.netloc or u.hostname))
    except (OSError, http.client.HTTPException) as e:
        die(0, "could not reach %s (%s)" % (u.hostname, getattr(e, "strerror", None) or e))

    if resp.status >= 400:
        try:
            raw = resp.read(65536)
        except Exception:
            raw = b""
        die(resp.status, err_text(raw) or resp.reason)

    st = Stream(kind)
    try:
        while True:
            raw = resp.readline()
            if not raw:
                break
            st.line(raw.decode("utf-8", "replace").strip())
    except socket.timeout:
        st.text("", final=True)
        die(0, "no data received for %d seconds" % int(idle_t))
    except (OSError, http.client.HTTPException) as e:
        # keep whatever was streamed so far; the panel offers to continue
        st.reason = st.reason or "eof"
        st.finish()
        return
    st.finish()


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
