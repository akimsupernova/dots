import QtQuick
import qs.common

Item {
    id: root

    property real u: Theme.u
    property string icon: ""
    property bool selected: false
    signal clicked()

    implicitHeight: Math.round(32 * u)

    Rectangle {
        anchors.centerIn: parent
        readonly property real d: Math.min(Math.round(30 * root.u), root.width - 2)
        width: d
        height: d
        radius: d / 2
        color: root.selected ? Qt.alpha(Theme.accent1, 0.9) : Theme.inkA(ma.containsMouse ? 0.16 : 0.07)
        Behavior on color { ColorAnimation { duration: 140 } }

        Icon {
            anchors.centerIn: parent
            name: root.icon
            size: Math.round(16 * root.u)
            color: root.selected ? "#101216" : Theme.ink
        }
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
