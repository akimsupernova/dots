#!/usr/bin/env python3

import json
import re
import signal
import subprocess
import sys

CLASS_INFO = {
    "08": ("storage", "drive-removable-media-usb"),
    "01": ("audio", "audio-headset"),
    "0e": ("camera", "camera-web"),
    "07": ("printer", "printer"),
    "09": ("hub", "preferences-desktop-peripherals"),
    "e0": ("bluetooth", "bluetooth"),
    "02": ("network", "network-wired"),
    "0a": ("network", "network-wired"),
    "03": ("input", "input-keyboard"),
}
PRIORITY = ["08", "e0", "01", "0e", "07", "02", "0a", "03", "09"]

ROOT_HUB = re.compile(r"^usb\d+$")

VENDOR_SUFFIX = re.compile(
    r"[,\s]+(?:co\.?,?\s*ltd\.?|corporation|corp\.?|incorporated|inc\.?|ltd\.?|gmbh)$",
    re.IGNORECASE,
)


def classify(props):
    raw = props.get("ID_USB_INTERFACES", "")
    entries = [e for e in raw.split(":") if len(e) == 6]
    classes = {e[:2].lower() for e in entries}

    for e in entries:
        if e[:2] == "03":
            proto = e[4:6]
            if proto == "02":
                return "mouse", "input-mouse"
            if proto == "01":
                return "keyboard", "input-keyboard"

    for code in PRIORITY:
        if code in classes:
            return CLASS_INFO[code]
    return "device", "preferences-desktop-peripherals"


def pretty(text):
    return text.replace("_", " ").strip()


def clean_vendor(text):
    text = pretty(text)
    while True:
        stripped = VENDOR_SUFFIX.sub("", text)
        if stripped == text:
            return text
        text = stripped


def device_name(props):
    vendor = clean_vendor(props.get("ID_VENDOR_FROM_DATABASE") or props.get("ID_VENDOR", ""))
    model = pretty(props.get("ID_MODEL_FROM_DATABASE") or props.get("ID_MODEL", ""))

    if vendor and model:
        if model.lower().startswith(vendor.lower()):
            return model
        return f"{vendor} {model}"
    if model or vendor:
        return model or vendor

    vid = props.get("ID_VENDOR_ID")
    pid = props.get("ID_MODEL_ID")
    if not (vid and pid) and props.get("PRODUCT"):
        parts = props["PRODUCT"].split("/")
        if len(parts) >= 2:
            vid, pid = parts[0].zfill(4), parts[1].zfill(4)
    if vid and pid:
        return f"USB device {vid}:{pid}"
    return "USB device"


def handle_event(props):
    if props.get("SUBSYSTEM") != "usb" or props.get("DEVTYPE") != "usb_device":
        return
    action = props.get("ACTION")
    if action not in ("add", "remove"):
        return

    if ROOT_HUB.match(props.get("DEVPATH", "").rsplit("/", 1)[-1]):
        return

    kind, icon = classify(props)
    print(json.dumps({
        "action": action,
        "name": device_name(props),
        "kind": kind,
        "icon": icon,
    }), flush=True)


def main():
    try:
        proc = subprocess.Popen(
            ["udevadm", "monitor", "--udev", "--property", "--subsystem-match=usb"],
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            bufsize=1,
        )
    except FileNotFoundError:
        print("udevadm was not found (is systemd/udev installed?)", file=sys.stderr)
        return 1

    def stop(*_):
        proc.terminate()
        sys.exit(0)

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGHUP, stop)

    props = {}
    try:
        for line in proc.stdout:
            line = line.rstrip("\n")
            if not line:
                if props:
                    handle_event(props)
                props = {}
            elif "=" in line and not line.startswith(("UDEV", "KERNEL")):
                key, _, value = line.partition("=")
                props[key] = value
    except (BrokenPipeError, KeyboardInterrupt):
        pass
    finally:
        if proc.poll() is None:
            proc.terminate()

    return 0 if proc.returncode in (0, None, -15) else 1


if __name__ == "__main__":
    sys.exit(main())
