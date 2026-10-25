pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.common

Singleton {
    id: root

    property int cfgGapsIn: 5
    property int cfgGapsOut: 10
    property int cfgRounding: 8
    property bool detected: false
    property bool _applied: false

    readonly property int gapBetween: Prefs.winGap >= 0 ? Prefs.winGap : root.cfgGapsIn * 2
    readonly property int gapEdge: Prefs.winGapOut >= 0 ? Prefs.winGapOut : root.cfgGapsOut
    readonly property int rounding: Prefs.winRounding >= 0 ? Prefs.winRounding : root.cfgRounding

    readonly property bool _anySet: Prefs.winGap >= 0 || Prefs.winGapOut >= 0 || Prefs.winRounding >= 0

    function init() { root.detect() }

    function detect() {
        detectProc.running = true
    }

    function _num(line, fallback) {
        try {
            const j = JSON.parse(line)
            if (j.int !== undefined) return parseInt(j.int)
            if (j.custom) return parseInt(String(j.custom).trim().split(/\s+/)[0])
        } catch (e) {}
        return fallback
    }

    function _apply() {
        if (!root.detected) return
        if (!root._anySet) {
            if (root._applied) {
                root._applied = false
                Quickshell.execDetached(["hyprctl", "reload"])
            }
            return
        }
        const general = []
        if (Prefs.winGap >= 0) general.push("gaps_in = " + Math.round(Prefs.winGap / 2))
        if (Prefs.winGapOut >= 0) general.push("gaps_out = " + Prefs.winGapOut)
        const parts = []
        if (general.length) parts.push("general = { " + general.join(", ") + " }")
        if (Prefs.winRounding >= 0) parts.push("decoration = { rounding = " + Prefs.winRounding + " }")
        root._applied = true
        Quickshell.execDetached(["hyprctl", "eval", "hl.config({ " + parts.join(", ") + " })"])
    }

    Process {
        id: detectProc
        command: ["sh", "-c",
            "for o in general:gaps_in general:gaps_out decoration:rounding; do hyprctl -j getoption $o | tr -d '\\n'; echo; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.split("\n").filter(l => l.trim().length > 0)
                if (lines.length >= 3) {
                    root.cfgGapsIn = root._num(lines[0], root.cfgGapsIn)
                    root.cfgGapsOut = root._num(lines[1], root.cfgGapsOut)
                    root.cfgRounding = root._num(lines[2], root.cfgRounding)
                    root.detected = true
                    applyTimer.restart()
                }
            }
        }
    }

    Timer {
        id: applyTimer
        interval: 200
        onTriggered: root._apply()
    }

    Connections {
        target: Prefs
        function onWinGapChanged() { applyTimer.restart() }
        function onWinGapOutChanged() { applyTimer.restart() }
        function onWinRoundingChanged() { applyTimer.restart() }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded") root.detect()
        }
    }
}
