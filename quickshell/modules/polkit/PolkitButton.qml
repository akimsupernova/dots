import QtQuick
import qs.common

Rectangle {
    id: btn

    property string text: ""
    property bool primary: false
    signal clicked()

    implicitWidth: label.implicitWidth + 32 * Theme.u
    implicitHeight: Math.round(26 * Theme.u)
    radius: height / 2
    opacity: enabled ? 1 : 0.4

    color: primary ? Qt.alpha(Theme.accent1, mouse.containsMouse ? 1 : 0.9)
                   : Theme.inkA(mouse.containsMouse ? 0.2 : 0.1)
    Behavior on color { ColorAnimation { duration: 120 } }

    scale: mouse.pressed ? 0.94 : (mouse.containsMouse ? 1.05 : 1)
    Behavior on scale { NumberAnimation { duration: 170; easing.type: Easing.OutBack } }

    Text {
        id: label
        anchors.centerIn: parent
        text: btn.text
        color: btn.primary ? "#101216" : Theme.ink
        font.family: Theme.font
        font.pixelSize: Math.round(10 * Theme.u)
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
