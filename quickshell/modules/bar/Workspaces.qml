import QtQuick
import Quickshell.Hyprland
import qs.common
import qs.services

Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        spacing: 6
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: 10

            delegate: Rectangle {
                id: pill

                required property int index
                readonly property int wsId: index + 1
                readonly property bool focused: Hyprland.focusedWorkspace?.id === wsId
                readonly property bool occupied: Hyprland.workspaces.values.some(w => w.id === wsId)

                anchors.verticalCenter: parent.verticalCenter
                height: 8
                width: focused ? 26 : 8
                radius: height / 2
                color: occupied ? Theme.dim : Theme.surface

                Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    opacity: pill.focused ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: Theme.accent1 }
                        GradientStop { position: 1; color: Theme.accent2 }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hypr.dispatch("hl.dsp.focus({ workspace = " + pill.wsId + " })")
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        acceptedButtons: Qt.NoButton
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0)
                Hypr.dispatch("hl.dsp.focus({ workspace = \"e-1\" })")
            else
                Hypr.dispatch("hl.dsp.focus({ workspace = \"e+1\" })")
        }
    }
}
