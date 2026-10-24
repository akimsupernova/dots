pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property color bg:      "#CC181A1B"
    readonly property color surface: "#26ffffff"
    readonly property color text:    "#ffffff"
    readonly property color dim:     "#ffffff"
    readonly property string defaultAccent: "#33ccff"
    property color _accent: defaultAccent
    Behavior on _accent { ColorAnimation { duration: 600; easing.type: Easing.OutCubic } }
    readonly property color accent1: Prefs.accent !== "" ? Prefs.accent : root._accent

    function setAccentFromJson(text) {
        try {
            const c = JSON.parse(text).accent
            if (typeof c === "string" && /^#[0-9a-fA-F]{6}$/.test(c)) {
                root._accent = c
                root.setGlassFromJson(JSON.parse(text).glass)
                return true
            }
        } catch (e) {}
        return false
    }

    FileView {
        path: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/quickshell/accent.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.setAccentFromJson(text())
        onLoadFailed: { root._accent = root.defaultAccent; root._autoMode = "light" }
    }

    readonly property color accent2: "#ffffff"

    readonly property color subtext: "#b3ffffff"
    readonly property color warn:    "#ff5c6c"
    readonly property color ok:      "#5be38a"

    property string glass: Prefs.glass
    property string _autoMode: "light"
    property var _glassSet: ({
        light: { tint: "#f4f7ff", ink: "#15171a", alpha: 0.66 },
        dark:  { tint: "#10131a", ink: "#f4f6fa", alpha: 0.72 }
    })

    readonly property string glassMode: glass === "auto" ? _autoMode : glass
    readonly property bool glassLight: glassMode === "light"
    readonly property var _cur: _glassSet[glassMode] ?? _glassSet.light

    property color ink: _cur.ink
    property color tint: _cur.tint
    property real panelAlpha: _cur.alpha
    Behavior on ink { ColorAnimation { duration: 600; easing.type: Easing.OutCubic } }
    Behavior on tint { ColorAnimation { duration: 600; easing.type: Easing.OutCubic } }
    Behavior on panelAlpha { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

    readonly property real u: Prefs.uiScale

    function _hex(c) { return typeof c === "string" && /^#[0-9a-fA-F]{6}$/.test(c) }
    function setGlassFromJson(g) {
        if (!g) return
        const next = { light: _glassSet.light, dark: _glassSet.dark }
        for (const k of ["light", "dark"]) {
            const v = g[k]
            if (v && _hex(v.tint) && _hex(v.ink) && typeof v.alpha === "number")
                next[k] = { tint: v.tint, ink: v.ink, alpha: Math.max(0.4, Math.min(0.95, v.alpha)) }
        }
        _glassSet = next
        if (g.auto === "light" || g.auto === "dark") _autoMode = g.auto
    }

    function inkA(a) { return Qt.rgba(ink.r, ink.g, ink.b, a) }

    readonly property int radius: Prefs.radius
    readonly property int gap:    Prefs.gap
    readonly property int barHeight: Prefs.barHeight

    readonly property string font: "Google Sans"
    readonly property int fontSize: Prefs.fontSize

    readonly property int textYOffset: 0
}
