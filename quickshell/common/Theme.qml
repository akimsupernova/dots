pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property color bg:      "#99000000"
    readonly property color surface: "#26ffffff"
    readonly property color text:    "#ffffff"
    readonly property color dim:     "#ffffff"
    readonly property string defaultAccent: "#33ccff"
    property color _accent: defaultAccent
    Behavior on _accent { ColorAnimation { duration: 600; easing.type: Easing.OutCubic } }
    readonly property color accent1: root._accent

    function setAccentFromJson(text) {
        try {
            const c = JSON.parse(text).accent
            if (typeof c === "string" && /^#[0-9a-fA-F]{6}$/.test(c)) {
                root._accent = c
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
        onLoadFailed: root._accent = root.defaultAccent
    }

    readonly property color accent2: "#ffffff"

    readonly property color subtext: "#b3ffffff"
    readonly property color warn:    "#ff5c6c"
    readonly property color ok:      "#5be38a"

    readonly property int radius: 5
    readonly property int gap:    5
    readonly property int barHeight: 25

    readonly property string font: "Google Sans Display"
    readonly property int fontSize: 13

    //adjust this if the font looks stupid
    readonly property int textYOffset: 0
}
