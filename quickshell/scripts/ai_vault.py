#!/usr/bin/env python3

import base64
import json
import os
import subprocess
import sys

MAGIC = "glassveil_vault"
VERSION = 1
SERVICE = "glassveil"
ACCOUNT = "ai-vault"


def out(obj):
    sys.stdout.write(json.dumps(obj, ensure_ascii=False) + "\n")
    sys.stdout.flush()
    sys.exit(0)


def fail(code, msg):
    out({"ok": False, "code": code, "error": msg})


try:
    from cryptography.hazmat.primitives.ciphers.aead import AESGCM
except Exception:
    AESGCM = None


def data_dir():
    base = os.environ.get("XDG_DATA_HOME") or os.path.join(os.path.expanduser("~"), ".local", "share")
    return os.path.join(base, "glassveil")


def keyfile_path():
    return os.path.join(data_dir(), "vault.key")


def _secret_tool(args, stdin=None, timeout=20):
    try:
        r = subprocess.run(["secret-tool"] + args, input=stdin, capture_output=True, timeout=timeout)
    except (OSError, subprocess.SubprocessError):
        return None
    return r


def keyring_get():
    r = _secret_tool(["lookup", "service", SERVICE, "account", ACCOUNT])
    if r is None or r.returncode != 0 or not r.stdout.strip():
        return None
    try:
        k = base64.b64decode(r.stdout.strip(), validate=True)
    except Exception:
        return None
    return k if len(k) == 32 else None


def keyring_set(key):
    r = _secret_tool(["store", "--label=Glassveil AI vault key", "service", SERVICE, "account", ACCOUNT],
                     stdin=base64.b64encode(key))
    return r is not None and r.returncode == 0 and keyring_get() == key


def keyfile_get():
    try:
        with open(keyfile_path(), "rb") as f:
            k = base64.b64decode(f.read().strip(), validate=True)
    except (OSError, ValueError):
        return None
    return k if len(k) == 32 else None


def keyfile_set(key):
    d = data_dir()
    os.makedirs(d, mode=0o700, exist_ok=True)
    try:
        os.chmod(d, 0o700)
    except OSError:
        pass
    fd = os.open(keyfile_path(), os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, "wb") as f:
        f.write(base64.b64encode(key) + b"\n")
        f.flush()
        os.fsync(f.fileno())


def load_key(create):
    k = keyring_get()
    if k:
        return k, "keyring"
    k = keyfile_get()
    if k:
        return k, "keyfile"
    if not create:
        return None, None
    k = os.urandom(32)
    if keyring_set(k):
        return k, "keyring"
    keyfile_set(k)
    return k, "keyfile"



def parse_envelope(raw):
    try:
        j = json.loads(raw)
    except ValueError:
        return None
    if isinstance(j, dict) and j.get(MAGIC) == VERSION:
        return j
    return None


def aad_for(path):
    return os.path.basename(path).encode("utf-8")


def encrypt(key, path, text):
    nonce = os.urandom(12)
    ct = AESGCM(key).encrypt(nonce, text.encode("utf-8"), aad_for(path))
    return json.dumps({
        MAGIC: VERSION,
        "alg": "AES-256-GCM",
        "nonce": base64.b64encode(nonce).decode("ascii"),
        "data": base64.b64encode(ct).decode("ascii"),
    })


def decrypt(key, path, env):
    nonce = base64.b64decode(env["nonce"])
    ct = base64.b64decode(env["data"])
    return AESGCM(key).decrypt(nonce, ct, aad_for(path)).decode("utf-8")


def atomic_write(path, content):
    d = os.path.dirname(path)
    os.makedirs(d, mode=0o700, exist_ok=True)
    tmp = "%s.tmp.%d" % (path, os.getpid())
    fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(content)
            f.flush()
            os.fsync(f.fileno())
        os.replace(tmp, path)
    except BaseException:
        try:
            os.unlink(tmp)
        except OSError:
            pass
        raise


def read_raw(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    except FileNotFoundError:
        return None


def cmd_read(path):
    if AESGCM is None:
        fail("nolib", "python-cryptography is not installed (sudo pacman -S python-cryptography)")
    raw = read_raw(path)
    if raw is None or not raw.strip():
        out({"ok": True, "text": "{}", "exists": False})

    env = parse_envelope(raw)
    if env is not None:
        key, _ = load_key(create=False)
        if key is None:
            fail("locked", "the encryption key was not found (keyring locked or vault.key missing)")
        try:
            out({"ok": True, "text": decrypt(key, path, env), "exists": True})
        except Exception:
            fail("corrupt", "could not decrypt the file (wrong key or damaged file)")

    try:
        parsed = json.loads(raw)
    except ValueError:
        fail("corrupt", "the file is neither valid JSON nor an encrypted file")
    migrated = False
    note = ""
    if parsed not in ({}, []):
        try:
            key, _ = load_key(create=True)
            atomic_write(path, encrypt(key, path, raw))
            migrated = True
        except Exception as e:
            note = "could not encrypt the old plain-text file: %s" % e
    out({"ok": True, "text": raw, "exists": True, "migrated": migrated, "note": note})


def cmd_write(path):
    if AESGCM is None:
        fail("nolib", "python-cryptography is not installed (sudo pacman -S python-cryptography)")
    try:
        req = json.loads(sys.stdin.buffer.readline().decode("utf-8"))
        text = req["text"]
        if not isinstance(text, str):
            raise ValueError("text must be a string")
    except Exception:
        fail("badreq", "bad request on stdin")

    existing = read_raw(path)
    has_vault = existing is not None and parse_envelope(existing) is not None
    try:
        key, _ = load_key(create=not has_vault)
    except Exception as e:
        fail("nokey", "could not create or store the encryption key: %s" % e)
    if key is None:
        fail("locked", "the encryption key was not found; refusing to overwrite the encrypted file")
    try:
        atomic_write(path, encrypt(key, path, text))
    except Exception as e:
        fail("io", "could not write the file: %s" % e)
    out({"ok": True})


def cmd_status():
    lines = []
    lines.append("cryptography module: %s" % ("ok" if AESGCM else "MISSING (install python-cryptography)"))
    kr = keyring_get()
    kf = keyfile_get()
    if kr:
        lines.append("key: system keyring (secret-tool)")
    if kf:
        lines.append("key: file %s" % keyfile_path())
    if not kr and not kf:
        lines.append("key: none yet (created on the first save)")
    print("\n".join(lines))


def main():
    a = sys.argv[1:]
    if len(a) == 2 and a[0] == "read":
        cmd_read(a[1])
    elif len(a) == 2 and a[0] == "write":
        cmd_write(a[1])
    elif len(a) == 1 and a[0] == "status":
        cmd_status()
    else:
        sys.stderr.write(__doc__)
        sys.exit(2)


if __name__ == "__main__":
    main()
