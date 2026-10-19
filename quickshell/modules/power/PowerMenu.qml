import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: host
    property bool open: false

    IpcHandler {
        target: "power"
        function toggle(): void { host.open = !host.open }
        function open(): void { host.open = true }
        function close(): void { host.open = false }
    }

    LazyLoader {
        active: host.open

        PanelWindow {
            id: panel

            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
                    ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)

            anchors { top: true; bottom: true; left: true; right: true }
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            WlrLayershell.namespace: "Glassveil Shell Power"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            HyprlandFocusGrab {
                windows: [panel]
                active: true
                onCleared: host.open = false
            }

            MouseArea {
                anchors.fill: parent
                onClicked: host.open = false
            }

            Timer {
                interval: 30
                running: true
                onTriggered: content.forceActiveFocus()
            }

            PowerMenuContent {
                id: content
                anchors.centerIn: parent

                onRequestClose: host.open = false
                onExecute: command => {
                    Quickshell.execDetached(command)
                    host.open = false
                }
            }
        }
    }
}
