import QtQuick
import qs.common

Row {
    id: root

    property color tint: Theme.ink
    property string icon: "speaker"
    property string text: ""
    spacing: 1

    Icon {
        anchors.verticalCenter: parent.verticalCenter
        name: root.icon
        size: 11
        color: root.tint
    }

    Text {
        visible: root.text !== ""
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        color: root.tint
        font.family: Theme.font
        font.pixelSize: 11
        font.bold: true
    }
}
