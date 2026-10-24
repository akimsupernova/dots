import QtQuick
import qs.common
import qs.services

Item {
    id: root

    visible: Weather.enabled && Weather.ready
    implicitWidth: visible ? row.implicitWidth + 2 : 0
    implicitHeight: Theme.barHeight

    Row {
        id: row
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            name: Weather.icon
            size: 15
            color: Theme.ink
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Weather.tempText
            color: Theme.ink
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 1
            font.bold: true
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Weather.refresh()
    }
}
