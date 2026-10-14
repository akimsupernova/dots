import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Row {
    spacing: 1

    Repeater {
        model: SystemTray.items

        delegate: MouseArea {
            id: item
            required property var modelData

            width: 15
            height: 14
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor

            onClicked: mouse => {
                if (mouse.button === Qt.LeftButton) modelData.activate()
                else modelData.secondaryActivate()
            }

            IconImage {
                anchors.fill: parent
                source: item.modelData.icon
            }
        }
    }
}
