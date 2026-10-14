import QtQuick
import qs.common

Rectangle {
    id: btn

    property string icon: ""
    property string label: ""
    property bool selected: false
    property bool active: false
    property bool dimmed: false

    signal clicked()
    signal hovered()

    implicitWidth: 140
    implicitHeight: 120
    radius: 12
    opacity: dimmed ? 0.35 : 1
    Behavior on opacity { NumberAnimation { duration: 150 } }

    color: selected ? Qt.alpha(Theme.text, 0.2) : (mouse.containsMouse ? Theme.surface : "transparent")
    border.width: 2
    border.color: active ? Theme.warn : (selected ? Theme.accent1 : Theme.surface)

    Column {
        anchors.centerIn: parent
        spacing: 12

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            name: btn.icon
            size: 40
            color: btn.active ? Theme.warn : Theme.text
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: btn.label
            color: Theme.text
            font.family: Theme.font
            font.pixelSize: Theme.fontSize + 1
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPositionChanged: btn.hovered()
        onClicked: btn.clicked()
    }
}
