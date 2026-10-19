import QtQuick
import QtQuick.Layouts
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common

Item {
    id: root
    readonly property var win: ToplevelManager.activeToplevel

    implicitHeight: Theme.barHeight

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: -3

        Text {
            Layout.fillWidth: true
            elide: Text.ElideRight
            color: Theme.ink
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 4
            text: root.win?.appId ?? "Desktop"
        }
        Text {
            Layout.fillWidth: true
            elide: Text.ElideRight
            color: Theme.ink
            font.family: Theme.font
            font.pixelSize: Theme.fontSize - 2
            text: root.win?.title ?? ("Workspace " + (Hyprland.focusedWorkspace?.id ?? 1))
        }
    }
}
