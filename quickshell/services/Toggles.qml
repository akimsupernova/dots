pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.common

Singleton {
    id: root

    property bool keepAwake: false
    property bool nightLight: false
    property bool nightAvailable: false
    readonly property int nightTemp: Prefs.nightTemp

    property bool _cycling: false
    property bool _primed: false
    property bool _inWindow: false

    Process {
        running: root.keepAwake
        command: ["systemd-inhibit", "--what=idle", "--who=Glassveil Shell",
                  "--why=Keep awake", "--mode=block", "sleep", "infinity"]
    }

    Process {
        running: root.nightLight && root.nightAvailable && !root._cycling
        command: ["hyprsunset", "-t", String(root.nightTemp)]
    }

    onNightTempChanged: {
        if (root.nightLight && root.nightAvailable) {
            root._cycling = true
            cycleTimer.restart()
        }
    }

    Timer {
        id: cycleTimer
        interval: 450
        onTriggered: root._cycling = false
    }

    Process {
        running: true
        command: ["sh", "-c", "command -v hyprsunset"]
        onExited: code => root.nightAvailable = code === 0
    }

    function _nowMin() {
        const d = new Date()
        return d.getHours() * 60 + d.getMinutes()
    }

    function _inSchedule() {
        const s = Prefs.nightStart
        const e = Prefs.nightEnd
        const n = root._nowMin()
        if (s === e) return false
        return s < e ? (n >= s && n < e) : (n >= s || n < e)
    }

    function _tick() {
        if (!Prefs.nightSchedule) { root._primed = false; return }
        const cur = root._inSchedule()
        if (!root._primed || cur !== root._inWindow) {
            root._primed = true
            root._inWindow = cur
            root.nightLight = cur
        }
    }

    Timer {
        interval: 30000
        repeat: true
        running: Prefs.nightSchedule
        triggeredOnStart: true
        onTriggered: root._tick()
    }

    Connections {
        target: Prefs
        function onNightScheduleChanged() { root._primed = false; root._tick() }
        function onNightStartChanged() { root._primed = false; root._tick() }
        function onNightEndChanged() { root._primed = false; root._tick() }
    }
}
