import QtQuick
import qs.common

Rectangle {
    id: btn

    property string text: ""
    property bool primary: false
    signal clicked()

    implicitWidth: label.implicitWidth + 36
    implicitHeight: 36
    radius: height / 2
    opacity: enabled ? 1 : 0.4

    color: primary ? (mouse.containsMouse ? Qt.lighter(Theme.accent1, 1.15) : Theme.accent1)
                   : (mouse.containsMouse ? Theme.surface : "transparent")

    Text {
        id: label
        anchors.centerIn: parent
        text: btn.text
        color: btn.primary ? "#101216" : Theme.accent1
        font.family: Theme.font
        font.pixelSize: Theme.fontSize + 1
        font.bold: true
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: btn.enabled
        cursorShape: Qt.PointingHandCursor
        onClicked: btn.clicked()
    }
}
