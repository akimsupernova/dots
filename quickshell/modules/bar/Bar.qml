import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import qs.common
import qs.services

PanelWindow {
    id: bar

    property var modelData
    screen: modelData
    visible: !LockState.locked

    anchors { top: true; left: true; right: true }
    margins { top: Theme.gap; left: Theme.gap; right: Theme.gap }
    implicitHeight: Theme.barHeight
    color: "transparent"

    WlrLayershell.namespace: "Glassveil Shell Bar"

    Rectangle {
        anchors.fill: parent
        radius: Theme.radius
        color: Theme.tint

        ActiveWindow {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.right: middle.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
        }

        Row {
            id: middle
            anchors.centerIn: parent
            spacing: 2.5

            BarGroup {
                Resources { Layout.alignment: Qt.AlignVCenter }
                Media     { Layout.alignment: Qt.AlignVCenter }
            }
            BarGroup {
                Workspaces { Layout.alignment: Qt.AlignVCenter }
            }
            BarGroup {
                Clock   { Layout.alignment: Qt.AlignVCenter }
            }
        }

        RowLayout {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.rightMargin: 5
            spacing: 0

            Tray {}
            StatusIcons {
                Layout.leftMargin: 10
                Layout.rightMargin: 6
            }
            Battery {}
            Volume {}
        }
    }
}
