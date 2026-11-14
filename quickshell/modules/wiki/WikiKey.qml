import QtQuick
import qs.common

Rectangle {
    id: root

    property string label: ""
    readonly property real u: Theme.u

    implicitHeight: Math.round(24 * u)
    implicitWidth: Math.max(implicitHeight, txt.implicitWidth + 14 * u)
    radius: 7 * u
    color: Theme.inkA(0.10)
    border.width: 1
    border.color: Theme.inkA(0.16)

    Text {
        id: txt
        anchors.centerIn: parent
        text: root.label
        color: WikiPalette.ink
        font.family: Theme.font
        font.pixelSize: Math.round(10.5 * root.u)
        font.weight: Font.Medium
    }
}
