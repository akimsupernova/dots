pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string script: Quickshell.env("HOME") + "/.config/quickshell/scripts/brightness.sh"

    property real level: 0.5
    property bool available: true
    property int pending: -1

    function reload() { getProc.running = true }

    function set(v) {
        root.level = Math.max(0.01, Math.min(1, v))
        root.pending = Math.round(root.level * 100)
        if (!setProc.running) flush()
    }

    function flush() {
        if (root.pending < 0) return
        setProc.command = ["sh", root.script, "set", String(root.pending)]
        root.pending = -1
        setProc.running = true
    }

    Process {
        id: getProc
        command: ["sh", root.script, "get"]
        environment: ({ NO_OSD: "1" })
        stdout: StdioCollector {
            onStreamFinished: {
                const v = parseInt(this.text.trim())
                if (!isNaN(v) && root.pending < 0) root.level = Math.max(0, Math.min(100, v)) / 100
            }
        }
        onExited: code => root.available = code === 0
    }

    Process {
        id: setProc
        environment: ({ NO_OSD: "1" })
        onExited: root.flush()
    }
}
