import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common

Rectangle {
    id: root

    property string code: ""
    property bool copied: false
    readonly property real u: Theme.u

    Layout.fillWidth: true
    implicitHeight: Math.round(34 * u)
    radius: 10 * u
    color: Theme.inkA(area.containsMouse ? 0.14 : 0.09)
    border.width: 1
    border.color: Theme.inkA(0.07)
    Behavior on color { ColorAnimation { duration: 120 } }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 12 * root.u
        anchors.right: tick.left
        anchors.rightMargin: 8 * root.u
        anchors.verticalCenter: parent.verticalCenter
        text: root.code
        elide: Text.ElideRight
        color: WikiPalette.ink
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: Math.round(10.5 * root.u)
    }

    Icon {
        id: tick
        anchors.right: parent.right
        anchors.rightMargin: 10 * root.u
        anchors.verticalCenter: parent.verticalCenter
        name: root.copied ? "check" : "copy"
        size: Math.round(13 * root.u)
        color: root.copied ? WikiPalette.hi : WikiPalette.inkFaint
        opacity: (area.containsMouse || root.copied) ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    Timer {
        id: resetTimer
        interval: 1400
        onTriggered: root.copied = false
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            Quickshell.execDetached(["wl-copy", root.code])
            root.copied = true
            resetTimer.restart()
        }
    }
}
