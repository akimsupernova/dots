pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int focusMin: 25
    property int shortMin: 5
    property int longMin: 15
    property int cyclesBeforeLong: 4

    property string mode: "focus"
    property bool running: false
    property int completed: 0
    property real endAt: 0
    property int remaining: 25 * 60

    readonly property int total: root.seconds(root.mode)
    readonly property real progress: root.total > 0 ? 1 - root.remaining / root.total : 0
    readonly property int cycleDone: root.completed % root.cyclesBeforeLong
    readonly property string clock: {
        const m = Math.floor(root.remaining / 60)
        const s = root.remaining % 60
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s
    }
    readonly property string modeLabel: root.mode === "focus" ? "Focus"
                                      : root.mode === "short" ? "Short break" : "Long break"

    function seconds(m) {
        return (m === "focus" ? root.focusMin : m === "short" ? root.shortMin : root.longMin) * 60
    }

    function tickNow() {
        root.remaining = Math.max(0, Math.ceil((root.endAt - Date.now()) / 1000))
        if (root.remaining <= 0) root.finish()
    }

    function start() {
        if (root.running) return
        root.endAt = Date.now() + root.remaining * 1000
        root.running = true
    }

    function pause() {
        if (!root.running) return
        root.tickNow()
        root.running = false
    }

    function toggle() { root.running ? root.pause() : root.start() }

    function reset() {
        root.running = false
        root.remaining = root.total
    }

    function setMode(m) {
        root.running = false
        root.mode = m
        root.remaining = root.seconds(m)
    }

    function skip() { root.advance(false) }

    function advance(countIt) {
        root.running = false
        if (root.mode === "focus") {
            if (countIt) root.completed++
            const long = countIt && root.completed > 0 && root.completed % root.cyclesBeforeLong === 0
            root.mode = long ? "long" : "short"
        } else {
            root.mode = "focus"
        }
        root.remaining = root.seconds(root.mode)
    }

    function finish() {
        const wasFocus = root.mode === "focus"
        root.advance(true)
        Sounds.play("focus-alarm")
        Quickshell.execDetached(["notify-send", "-a", "Pomodoro", "-u", "normal",
            wasFocus ? "Focus session finished" : "Break is over",
            wasFocus ? ("Time for a " + (root.mode === "long" ? "long" : "short") + " break.")
                     : "Ready for the next focus session?"])
    }

    function adjust(delta) {
        if (root.running) return
        const step = root.mode === "short" ? 1 : 5
        const d = delta * step
        if (root.mode === "focus") root.focusMin = Math.max(5, Math.min(90, root.focusMin + d))
        else if (root.mode === "short") root.shortMin = Math.max(1, Math.min(30, root.shortMin + d))
        else root.longMin = Math.max(5, Math.min(60, root.longMin + d))
        root.remaining = root.total
    }

    readonly property int currentMin: root.mode === "focus" ? root.focusMin
                                    : root.mode === "short" ? root.shortMin : root.longMin

    Timer {
        interval: 250
        running: root.running
        repeat: true
        onTriggered: root.tickNow()
    }

    IpcHandler {
        target: "pomodoro"
        function toggle(): void { root.toggle() }
        function reset(): void { root.reset() }
        function skip(): void { root.skip() }
    }
}
