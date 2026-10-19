import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.services

Scope {
    id: root

    readonly property var focusedScreen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
                                         ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)

    LazyLoader {
        active: PolkitService.active

        PanelWindow {
            screen: root.focusedScreen
            anchors { top: true; bottom: true; left: true; right: true }
            exclusiveZone: 0
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"

            WlrLayershell.namespace: "Glassveil Shell Polkit"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            PolkitContent { anchors.fill: parent }
        }
    }
}
