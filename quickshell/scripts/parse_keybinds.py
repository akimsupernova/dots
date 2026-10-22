#!/usr/bin/env python3
"""Parse hypr modules/keybinds.lua → JSON map of key combo → action label.

Supports:
  hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(p.browser))
  hl.bind("SUPER + W", hl.dsp.exec_cmd(p.browser), { description = "App: Browser" })
  hl.bind(..., { description = "App: Browser" })

Description format "Category: Label" → cheatsheet shows "Label", groups by "Category".
"""
import json
import os
import re
from pathlib import Path

path = Path(os.path.expanduser("~/.config/hypr/modules/keybinds.lua"))
text = path.read_text() if path.exists() else ""
out = {}

def clean_key(keypart: str) -> str:
    keypart = re.sub(r"mainMod\s*\.\.\s*", "Super", keypart)
    keypart = keypart.replace('"', "").replace("'", "")
    keypart = re.sub(r"\s+", "", keypart)
    keypart = re.sub(r"SUPER", "Super", keypart, flags=re.I)
    keypart = re.sub(r"SHIFT", "Shift", keypart, flags=re.I)
    keypart = re.sub(r"CTRL|CONTROL", "Ctrl", keypart, flags=re.I)
    keypart = re.sub(r"ALT", "Alt", keypart, flags=re.I)
    return keypart

def extract_description(expr: str):
    """Extract description = \"...\" from bind options."""
    m = re.search(
        r"description\s*=\s*[\"']([^\"']+)[\"']",
        expr,
        re.I,
    )
    if not m:
        return None
    desc = m.group(1).strip()
    if ":" in desc:
        cat, label = desc.split(":", 1)
        label = label.strip()
        return label if label else desc
    return desc

def fallback_action(act: str) -> str:
    action = act.strip()
    if "exec_cmd" in act:
        mm = re.search(r"exec_cmd\((.+)\)\s*$", act)
        if mm:
            action = mm.group(1).strip().strip("\"'")
            action = re.split(r"\)\s*,\s*\{", action)[0]
            if action.startswith("[["):
                action = action[2:]
            if action.endswith("]]"):
                action = action[:-2]
            if len(action) > 70:
                action = action[:67] + "…"
    elif "window.close" in act:
        action = "Close window"
    elif "window.float" in act:
        action = "Toggle float"
    elif "window.pseudo" in act:
        action = "Pseudo tile"
    elif "window.move" in act and "workspace" in act:
        action = "Move to workspace"
    elif "focus" in act and "workspace" in act:
        action = "Focus workspace"
    elif "focus" in act and "direction" in act:
        action = "Move focus"
    elif "toggle_special" in act:
        action = "Toggle special workspace"
    elif "window.move" in act and "special" in act:
        action = "Move to special workspace"
    elif "layout" in act:
        action = "Toggle split"
    elif "window.drag" in act:
        action = "Drag window"
    elif "window.resize" in act:
        action = "Resize window"
    else:
        action = re.sub(r"^hl\.dsp\.", "", action)
        if len(action) > 70:
            action = action[:67] + "…"
    return action

for m in re.finditer(r"hl\.bind\((.+?)\)\s*(?:$|--)", text, re.M):
    expr = m.group(1)

    parts = re.split(r",\s*", expr, maxsplit=1)
    if len(parts) < 2:
        continue
    keypart, rest = parts[0], parts[1]
    key = clean_key(keypart)

    desc = extract_description(expr)
    if desc:
        out[key] = desc
        continue

    out[key] = fallback_action(rest)

print(json.dumps(out, ensure_ascii=False))
