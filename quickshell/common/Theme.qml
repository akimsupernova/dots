pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property color bg:      "#99000000"
    readonly property color surface: "#26ffffff"
    readonly property color text:    "#ffffff"
    readonly property color dim:     "#ffffff"
    readonly property color accent1: "#33ccff"
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
    readonly property int textYOffset: 1
}
