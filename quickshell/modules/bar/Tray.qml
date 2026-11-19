import QtQuick
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Row {
    spacing: 5

    Repeater {
        model: SystemTray.items

        delegate: MouseArea {
            id: item
            required property var modelData

            width: 15
            height: 15
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            cursorShape: Qt.PointingHandCursor

            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    if (modelData.hasMenu) menu.toggle()
                } else if (mouse.button === Qt.MiddleButton) {
                    modelData.secondaryActivate()
                } else if (modelData.onlyMenu && modelData.hasMenu) {
                    menu.toggle()
                } else {
                    modelData.activate()
                }
            }

            IconImage {
                anchors.fill: parent
                source: item.modelData.icon
            }

            TrayMenu {
                id: menu
                trayItem: item.modelData
                anchorItem: item
            }
        }
    }
}
