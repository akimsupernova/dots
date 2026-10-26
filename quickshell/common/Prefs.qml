pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string glass: "auto"
    property string accent: ""
    property real uiScale: 1.25
    property int barHeight: 25
    property int gap: 5
    property int radius: 5
    property int winGap: -1
    property int winGapOut: -1
    property int winRounding: -1
    property int fontSize: 13

    property bool barTitle: true
    property bool barResources: true
    property bool barMedia: true
    property bool barWorkspaces: true
    property bool barClock: true
    property bool barTray: true
    property bool barStatus: true
    property bool barBattery: true
    property bool barVolume: true

    property string clockStyle: "digital"
    property real clockZoom: 1.0
    property string clockRing: "day"
    property bool clockDate: true
    property bool clockWeather: true
    property bool clock24h: true

    property int audioStep: 2
    property int audioMax: 100
    property bool audioOsd: true

    property string aiStyle: "default"
    property bool aiInstructionsOn: true
    property string aiInstructions: ""
    property int aiWidth: 520
    property int aiChatHeight: 340
    property int aiBottom: 70
    property bool aiDraggable: false
    property string aiDragKey: "alt"
    property bool aiRemember: true
    property int aiX: 0
    property int aiY: 0
    property bool aiCloseOutside: true
    property string aiTheme: "none"
    property string aiThemeLevel: "medium"

    property int notifTimeout: 2
    property int notifMax: 4
    property bool notifCriticalSticky: false

    property string lockWhen: "battery"
    property int lockTimeout: 3
    property bool lockScreenOff: true

    property int nightTemp: 4200
    property bool nightSchedule: false
    property int nightStart: 1260
    property int nightEnd: 360

    readonly property var _schema: ({
        glass:        { t: "enum", v: ["auto", "light", "dark"] },
        accent:       { t: "hex" },
        uiScale:      { t: "num", min: 1.0, max: 1.6 },
        barHeight:    { t: "num", min: 20, max: 40, int: true },
        gap:          { t: "num", min: 0, max: 12, int: true },
        radius:       { t: "num", min: 0, max: 20, int: true },
        winGap:       { t: "num", min: -1, max: 40, int: true },
        winGapOut:    { t: "num", min: -1, max: 60, int: true },
        winRounding:  { t: "num", min: -1, max: 30, int: true },
        fontSize:     { t: "num", min: 11, max: 16, int: true },
        barTitle:     { t: "bool" },
        barResources: { t: "bool" },
        barMedia:     { t: "bool" },
        barWorkspaces:{ t: "bool" },
        barClock:     { t: "bool" },
        barTray:      { t: "bool" },
        barStatus:    { t: "bool" },
        barBattery:   { t: "bool" },
        barVolume:    { t: "bool" },
        clockStyle:   { t: "enum", v: ["digital", "ring"] },
        clockZoom:    { t: "num", min: 0.5, max: 2.5 },
        clockRing:    { t: "enum", v: ["day", "battery"] },
        clockDate:    { t: "bool" },
        clockWeather: { t: "bool" },
        clock24h:     { t: "bool" },
        audioStep:    { t: "num", min: 1, max: 10, int: true },
        audioMax:     { t: "num", min: 100, max: 150, int: true },
        audioOsd:     { t: "bool" },
        aiStyle:      { t: "enum", v: ["default", "concise", "detailed"] },
        aiInstructionsOn: { t: "bool" },
        aiInstructions:   { t: "str", max: 1500 },
        aiWidth:      { t: "num", min: 320, max: 900, int: true },
        aiChatHeight: { t: "num", min: 200, max: 700, int: true },
        aiBottom:     { t: "num", min: 0, max: 600, int: true },
        aiDraggable:  { t: "bool" },
        aiDragKey:    { t: "enum", v: ["alt", "ctrl", "shift"] },
        aiRemember:   { t: "bool" },
        aiX:          { t: "num", min: -20000, max: 20000, int: true },
        aiY:          { t: "num", min: -20000, max: 20000, int: true },
        aiCloseOutside: { t: "bool" },
        aiTheme:      { t: "enum", v: ["none", "rain", "meteor"] },
        aiThemeLevel: { t: "enum", v: ["low", "medium", "high"] },
        notifTimeout: { t: "num", min: 1, max: 15, int: true },
        notifMax:     { t: "num", min: 1, max: 8, int: true },
        notifCriticalSticky: { t: "bool" },
        lockWhen:     { t: "enum", v: ["battery", "always", "never"] },
        lockTimeout:  { t: "num", min: 1, max: 60, int: true },
        lockScreenOff:{ t: "bool" },
        nightTemp:    { t: "num", min: 2500, max: 6500, int: true },
        nightSchedule:{ t: "bool" },
        nightStart:   { t: "num", min: 0, max: 1439, int: true },
        nightEnd:     { t: "num", min: 0, max: 1439, int: true }
    })

    readonly property string dir: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/glassveil"
    readonly property string file: dir + "/settings.json"

    property var _defaults: ({})
    property bool _ready: false
    property real _lastWrite: 0
    property bool _themeDirty: false
    property bool _syncAgain: false

    readonly property string themeScript: Quickshell.env("HOME") + "/.config/quickshell/scripts/theme_sync.py"

    function _runThemeSync() {
        if (themeSync.running) { root._syncAgain = true; return }
        themeSync.command = ["python3", root.themeScript, "--glass", root.glass, "--pref-accent", root.accent]
        themeSync.running = true
    }

    function _coerce(k, v) {
        const s = root._schema[k]
        if (!s) return undefined
        if (s.t === "bool") return typeof v === "boolean" ? v : undefined
        if (s.t === "enum") return s.v.indexOf(v) >= 0 ? v : undefined
        if (s.t === "str") return typeof v === "string" ? v.slice(0, s.max) : undefined
        if (s.t === "hex") {
            if (v === "") return ""
            return (typeof v === "string" && /^#[0-9a-fA-F]{6}$/.test(v)) ? v.toLowerCase() : undefined
        }
        if (s.t === "num") {
            if (typeof v !== "number" || !isFinite(v)) return undefined
            const c = Math.max(s.min, Math.min(s.max, v))
            return s.int ? Math.round(c) : Math.round(c * 100) / 100
        }
        return undefined
    }

    function set(key, value) {
        const c = root._coerce(key, value)
        if (c === undefined || root[key] === c) return
        root[key] = c
        if (key === "glass" || key === "accent") root._themeDirty = true
        saveTimer.restart()
    }

    function resetAll() {
        for (const k in root._defaults) root[k] = root._defaults[k]
        root._themeDirty = true
        saveTimer.restart()
    }

    function _apply(raw) {
        let j = null
        try { j = JSON.parse(raw) } catch (e) { return }
        if (!j || typeof j !== "object") return
        for (const k in root._schema) {
            if (!(k in j)) continue
            const c = root._coerce(k, j[k])
            if (c !== undefined && root[k] !== c) root[k] = c
        }
    }

    function _save() {
        const o = {}
        for (const k in root._schema) o[k] = root[k]
        root._lastWrite = Date.now()
        store.setText(JSON.stringify(o, null, 2) + "\n")
        if (root._themeDirty) {
            root._themeDirty = false
            root._runThemeSync()
        }
    }

    Component.onCompleted: {
        const d = {}
        for (const k in root._schema) d[k] = root[k]
        root._defaults = d
    }

    Process {
        running: true
        command: ["mkdir", "-p", root.dir]
        onExited: root._ready = true
    }

    Process {
        id: themeSync
        onExited: {
            if (root._syncAgain) { root._syncAgain = false; root._runThemeSync() }
        }
    }

    FileView {
        id: store
        path: root._ready ? root.file : ""
        watchChanges: true
        onFileChanged: {
            if (saveTimer.running || Date.now() - root._lastWrite < 1500) return
            reload()
        }
        onLoaded: root._apply(text())
    }

    Timer {
        id: saveTimer
        interval: 400
        onTriggered: root._save()
    }
}
