pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string dir: (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/glassveil/notepad"
    readonly property string textPath: root.dir + "/note.txt"
    readonly property string statePath: root.dir + "/state.json"

    property string text: ""
    property var strokes: []

    property real geoX: -1
    property real geoY: -1
    property real geoW: 0
    property real geoH: 0

    property int brushSize: 3
    property string brushColor: "accent"

    property bool _ready: false
    property var _undo: []
    property var _redo: []

    signal textLoaded()
    signal saved()

    function init() {}

    function updateText(t) {
        if (t === root.text) return
        root.text = t
        textTimer.restart()
    }

    function _snapshot() {
        root._undo = [...root._undo.slice(-99), root.strokes]
        root._redo = []
    }
    function addStroke(s) {
        root._snapshot()
        root.strokes = root.strokes.concat([s])
        stateTimer.restart()
    }
    function replaceStrokes(list, snapshot) {
        if (snapshot) root._snapshot()
        root.strokes = list
        stateTimer.restart()
    }
    function clearStrokes() {
        if (root.strokes.length === 0) return
        root._snapshot()
        root.strokes = []
        stateTimer.restart()
    }
    function undo() {
        if (root._undo.length === 0) return
        root._redo = [...root._redo, root.strokes]
        root.strokes = root._undo[root._undo.length - 1]
        root._undo = root._undo.slice(0, -1)
        stateTimer.restart()
    }
    function redo() {
        if (root._redo.length === 0) return
        root._undo = [...root._undo, root.strokes]
        root.strokes = root._redo[root._redo.length - 1]
        root._redo = root._redo.slice(0, -1)
        stateTimer.restart()
    }

    function setBrushSize(n) {
        const v = Math.max(1, Math.min(32, Math.round(n)))
        if (v === root.brushSize) return
        root.brushSize = v
        stateTimer.restart()
    }
    function setBrushColor(c) {
        if (c === root.brushColor) return
        root.brushColor = c
        stateTimer.restart()
    }
    function setGeometry(x, y, w, h) {
        root.geoX = Math.round(x)
        root.geoY = Math.round(y)
        root.geoW = Math.round(w)
        root.geoH = Math.round(h)
        stateTimer.restart()
    }

    function _writeText() {
        textTimer.stop()
        if (root._ready) textView.setText(root.text)
    }
    function _writeState() {
        stateTimer.stop()
        if (!root._ready) return
        stateView.setText(JSON.stringify({
            v: 1,
            x: root.geoX, y: root.geoY, w: root.geoW, h: root.geoH,
            brush: { size: root.brushSize, color: root.brushColor },
            strokes: root.strokes
        }))
    }
    function flush() {
        if (textTimer.running) root._writeText()
        if (stateTimer.running) root._writeState()
    }
    function saveNow() {
        root._writeText()
        root._writeState()
        root.saved()
    }

    function _validColor(c) {
        return typeof c === "string" && (c === "accent" || c === "ink" || /^#[0-9a-fA-F]{6}$/.test(c))
    }
    function _num(v, lo, hi, fallback) {
        return (typeof v === "number" && isFinite(v)) ? Math.max(lo, Math.min(hi, v)) : fallback
    }

    function _applyState(raw) {
        let j = null
        try { j = JSON.parse(raw) } catch (e) { return }
        if (!j || typeof j !== "object") return

        root.geoX = root._num(j.x, -1, 20000, -1)
        root.geoY = root._num(j.y, -1, 20000, -1)
        root.geoW = root._num(j.w, 0, 20000, 0)
        root.geoH = root._num(j.h, 0, 20000, 0)

        if (j.brush && typeof j.brush === "object") {
            root.brushSize = Math.round(root._num(j.brush.size, 1, 32, 3))
            if (root._validColor(j.brush.color)) root.brushColor = j.brush.color
        }

        if (Array.isArray(j.strokes)) {
            const out = []
            for (const s of j.strokes.slice(0, 5000)) {
                if (!s || !root._validColor(s.c) || !Array.isArray(s.p)) continue
                if (s.p.length < 2 || s.p.length % 2 !== 0 || s.p.length > 40000) continue
                if (!s.p.every(n => typeof n === "number" && isFinite(n))) continue
                out.push({ c: s.c, w: root._num(s.w, 1, 32, 3), p: s.p })
            }
            root.strokes = out
        }
    }

    Process {
        running: true
        command: ["mkdir", "-p", root.dir]
        onExited: root._ready = true
    }

    FileView {
        id: textView
        path: root._ready ? root.textPath : ""
        onLoaded: {
            root.text = text()
            root.textLoaded()
        }
    }

    FileView {
        id: stateView
        path: root._ready ? root.statePath : ""
        onLoaded: root._applyState(text())
    }

    Timer {
        id: textTimer
        interval: 600
        onTriggered: root._writeText()
    }

    Timer {
        id: stateTimer
        interval: 500
        onTriggered: root._writeState()
    }
}
