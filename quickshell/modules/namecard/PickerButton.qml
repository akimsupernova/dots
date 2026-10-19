import QtQuick
import qs.common

Rectangle {
    id: b

    property real u: 1
    property string icon: ""
    property string text: ""
    property color ink: "#15171a"
    signal clicked()

    implicitHeight: Math.round(24 * u)
    implicitWidth: row.implicitWidth + 16 * u
    radius: height / 2
    color: Qt.rgba(ink.r, ink.g, ink.b, area.containsMouse ? 0.22 : 0.12)
    Behavior on color { ColorAnimation { duration: 120 } }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5 * b.u
        Icon {
            visible: b.icon !== ""
            anchors.verticalCenter: parent.verticalCenter
            name: b.icon
            size: Math.round(11 * b.u)
            color: b.ink
        }
        Text {
            visible: b.text !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: b.text
            color: b.ink
            font.family: Theme.font
            font.pixelSize: Math.round(9.5 * b.u)
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: b.clicked()
    }
}
