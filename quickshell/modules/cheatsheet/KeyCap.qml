import QtQuick
import qs.common

Rectangle {
    id: keyRoot

    property string label: ""
    property bool emphasis: false
    property real u: Theme.u
    property real hPad: 7 * u
    property real vPad: 2 * u

    implicitWidth: face.implicitWidth + 2
    implicitHeight: face.implicitHeight + 2 + 3
    radius: 6 * u
    color: Theme.inkA(emphasis ? 0.38 : 0.24)

    HoverHandler { id: hh }

    Rectangle {
        id: face
        anchors {
            fill: parent
            topMargin: hh.hovered ? 3 : 1
            leftMargin: 1
            rightMargin: 1
            bottomMargin: hh.hovered ? 1 : 3
        }
        Behavior on anchors.topMargin { NumberAnimation { duration: 90 } }
        Behavior on anchors.bottomMargin { NumberAnimation { duration: 90 } }
        radius: keyRoot.radius - 1
        color: Theme.glassLight ? (keyRoot.emphasis ? "#ffffff" : "#f0f3fa")
                                : (keyRoot.emphasis ? "#2f333d" : "#262a33")
        implicitWidth: txt.implicitWidth + keyRoot.hPad * 2
        implicitHeight: txt.implicitHeight + keyRoot.vPad * 2

        Text {
            id: txt
            anchors.centerIn: parent
            text: keyRoot.label
            color: Theme.ink
            font.pixelSize: Math.round(9.5 * keyRoot.u)
            font.family: Theme.font
            font.weight: Font.Medium
        }
    }
}
