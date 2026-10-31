pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

Singleton {
    id: root

    readonly property string script: Quickshell.env("HOME") + "/.config/quickshell/scripts/usb_monitor.py"
    readonly property bool enabled: Prefs.notifUsb

    function init() {}

    function handleLine(line) {
        let ev = null
        try { ev = JSON.parse(line) } catch (e) { return }
        if (!ev || (ev.action !== "add" && ev.action !== "remove")) return
        if (!root.enabled) return

        const added = ev.action === "add"
        Quickshell.execDetached([
            "notify-send",
            "-a", "USB",
            "-i", ev.icon || "drive-removable-media-usb",
            added ? "USB device connected" : "USB device removed",
            ev.name || "USB device"
        ])
    }

    onEnabledChanged: watcher.running = root.enabled
    Component.onCompleted: watcher.running = root.enabled

    Process {
        id: watcher
        command: ["python3", root.script]

        stdout: SplitParser {
            onRead: line => root.handleLine(line)
        }

        onExited: if (root.enabled) restartTimer.restart()
    }

    Timer {
        id: restartTimer
        interval: 5000
        onTriggered: if (root.enabled) watcher.running = true
    }
}
